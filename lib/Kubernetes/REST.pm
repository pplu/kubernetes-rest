package Kubernetes::REST;
# ABSTRACT: A Perl REST Client for the Kubernetes API
use Moo;
use Carp qw(croak carp);
use Scalar::Util qw(blessed);
use Module::Runtime qw(require_module);
use JSON::MaybeXS ();
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::HTTPTinyIO;
use Kubernetes::REST::HTTPRequest;
use IO::K8s;
use IO::K8s::List;
use Kubernetes::REST::WatchEvent;

has server => (
    is => 'ro',
    required => 1,
    coerce => sub {
        my $val = $_[0];
        return $val if blessed($val) && $val->isa('Kubernetes::REST::Server');
        Kubernetes::REST::Server->new($val);
    },
);

has credentials => (
    is => 'ro',
    required => 1,
    coerce => sub {
        my $val = $_[0];
        return $val if blessed($val) && $val->can('token');
        return Kubernetes::REST::AuthToken->new($val) if ref($val) eq 'HASH';
        return $val;
    }
);

has io => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Kubernetes::REST::HTTPTinyIO->new(
            ssl_verify_server => $self->server->ssl_verify_server,
            ssl_cert_file => $self->server->ssl_cert_file,
            ssl_key_file => $self->server->ssl_key_file,
            ssl_ca_file => $self->server->ssl_ca_file,
        );
    },
);

has _json => (is => 'ro', default => sub { JSON::MaybeXS->new });

# IO::K8s instance - configured with same resource_map
has k8s => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return IO::K8s->new(
            resource_map => $self->resource_map,
        );
    },
    handles => [qw(
        new_object
        inflate
        json_to_object
        struct_to_object
        expand_class
    )],
);

# Set to 0 to use IO::K8s defaults instead of loading from cluster
has resource_map_from_cluster => (is => 'ro', default => sub { 1 });

# Cluster version - fetched once per instance
has cluster_version => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $response = $self->_request('GET', '/version');
        return 'unknown' if $response->status >= 400;
        my $info = $self->_json->decode($response->content);
        return $info->{gitVersion} // 'unknown';
    },
);

# Resource map - loads from cluster by default, cached per instance (lazy)
has resource_map => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return IO::K8s->default_resource_map unless $self->resource_map_from_cluster;
        return $self->_load_resource_map_from_cluster;
    },
);

# Public method to fetch resource map from cluster's OpenAPI spec
sub fetch_resource_map {
    my ($self) = @_;

    my $response = $self->_request('GET', '/openapi/v2');

    if ($response->status >= 400) {
        croak "Could not load resource map from cluster: " . $response->status;
    }

    my $spec = $self->_json->decode($response->content);
    my %map;

    for my $path (keys %{$spec->{paths} // {}}) {
        my $methods = $spec->{paths}{$path};
        for my $method (keys %$methods) {
            my $op = $methods->{$method};
            next unless ref $op eq 'HASH';
            my $gvk = $op->{'x-kubernetes-group-version-kind'};
            next unless $gvk;

            my $kind = $gvk->{kind} // '';
            my $version = $gvk->{version} // '';
            my $group = $gvk->{group} // '';

            next if $kind =~ /List$/;
            next unless $kind && $version;

            my $version_path = ucfirst($version);
            my $new_path;

            # Extension APIs have different base paths in IO::K8s
            if ($group eq 'apiextensions.k8s.io') {
                my $group_path = 'Apiextensions';
                $new_path = "ApiextensionsApiserver::Pkg::Apis::${group_path}::${version_path}::${kind}";
            } elsif ($group eq 'apiregistration.k8s.io') {
                my $group_path = 'Apiregistration';
                $new_path = "KubeAggregator::Pkg::Apis::${group_path}::${version_path}::${kind}";
            } else {
                # Standard API resources use Api:: prefix
                my $group_path = $group eq '' ? 'Core' : ucfirst(lc((split /\./, $group)[0]));
                $new_path = "Api::${group_path}::${version_path}::${kind}";
            }

            # Prefer stable versions
            if (!$map{$kind} || $version !~ /alpha|beta/) {
                $map{$kind} = $new_path;
            }
        }
    }

    return \%map;
}

# Fetch full OpenAPI spec from cluster (cached)
has _openapi_spec => (
    is => 'lazy',
    builder => sub {
        my $self = shift;
        my $response = $self->_request('GET', '/openapi/v2');
        croak "Could not fetch OpenAPI spec: " . $response->status if $response->status >= 400;
        return $self->_json->decode($response->content);
    },
);

# Get schema definition for a specific type
# $kind can be: 'Pod', 'IO::K8s::Api::Core::V1::Pod', or OpenAPI name like 'io.k8s.api.core.v1.Pod'
sub schema_for {
    my ($self, $kind) = @_;

    my $spec = $self->_openapi_spec;
    my $defs = $spec->{definitions} // {};

    # If it's already an OpenAPI definition name
    if (exists $defs->{$kind}) {
        return $defs->{$kind};
    }

    # Convert class name to OpenAPI definition name
    my $class = $self->expand_class($kind);
    # IO::K8s::Api::Core::V1::Pod -> io.k8s.api.core.v1.Pod
    my $def_name = $class;
    $def_name =~ s/^IO::K8s:://;
    $def_name =~ s/::/./g;
    $def_name = 'io.k8s.' . $def_name;
    # Lowercase all path components except the final type name
    my @parts = split /\./, $def_name;
    $parts[$_] = lc($parts[$_]) for 0 .. $#parts - 1;
    $def_name = join '.', @parts;

    return $defs->{$def_name};
}

# Compare local class against cluster schema
# Returns comparison result from IO::K8s::Resource->compare_to_schema
sub compare_schema {
    my ($self, $kind) = @_;

    my $class = $self->expand_class($kind);
    require_module($class);

    my $schema = $self->schema_for($kind);
    croak "Schema not found for $kind" unless $schema;

    return $class->compare_to_schema($schema);
}

# Internal wrapper with fallback for lazy loading
sub _load_resource_map_from_cluster {
    my ($self) = @_;
    my $map = eval { $self->fetch_resource_map };
    if ($@) {
        carp "Could not load resource map from cluster, using default: $@";
        return IO::K8s->default_resource_map;
    }
    return $map;
}

# V0 API compatibility - returns group wrapper objects
sub _v0_group {
    my ($self, $group) = @_;
    my $class = "Kubernetes::REST::$group";
    require_module($class);
    return $class->new(api => $self);
}

sub Core { shift->_v0_group('Core') }
sub Apps { shift->_v0_group('Apps') }
sub Batch { shift->_v0_group('Batch') }
sub Networking { shift->_v0_group('Networking') }
sub Storage { shift->_v0_group('Storage') }
sub Policy { shift->_v0_group('Policy') }
sub Autoscaling { shift->_v0_group('Autoscaling') }
sub RbacAuthorization { shift->_v0_group('RbacAuthorization') }
sub Certificates { shift->_v0_group('Certificates') }
sub Coordination { shift->_v0_group('Coordination') }
sub Events { shift->_v0_group('Events') }
sub Scheduling { shift->_v0_group('Scheduling') }
sub Authentication { shift->_v0_group('Authentication') }
sub Authorization { shift->_v0_group('Authorization') }
sub Admissionregistration { shift->_v0_group('Admissionregistration') }
sub Apiextensions { shift->_v0_group('Apiextensions') }
sub Apiregistration { shift->_v0_group('Apiregistration') }

# Build URL path from class metadata
sub _build_path {
    my ($self, $class, %args) = @_;

    require_module($class);

    # Get metadata from class
    my $api_version = $class->can('api_version') ? $class->api_version : undef;
    croak "Cannot determine api_version for $class - override api_version() in your CRD class"
        unless defined $api_version;
    my $kind = $class->can('kind') ? $class->kind : (split('::', $class))[-1];
    my $is_namespaced = $class->does('IO::K8s::Role::Namespaced');

    # Use explicit resource_plural if available, otherwise auto-pluralize
    my $resource;
    if ($class->can('resource_plural') && $class->resource_plural) {
        $resource = $class->resource_plural;
    } else {
        $resource = lc($kind);
        $resource .= 's' unless $resource =~ /s$/;
        # Handle special plurals
        $resource =~ s/ys$/ies/;  # Policy -> policies
        $resource =~ s/sss$/ses/; # Status -> statuses
    }

    # Build path based on API group
    my $path;
    if ($api_version =~ m{/}) {
        # Has group: apps/v1 -> /apis/apps/v1/...
        $path = "/apis/$api_version";
    } else {
        # Core: v1 -> /api/v1/...
        $path = "/api/$api_version";
    }

    if ($is_namespaced && $args{namespace}) {
        $path .= "/namespaces/$args{namespace}";
    }

    $path .= "/$resource";

    if ($args{name}) {
        $path .= "/$args{name}";
    }

    return $path;
}

# ============================================================================
# REQUEST / RESPONSE PIPELINE
#
# The API methods (list, get, create, etc.) are built on a 3-step pipeline:
#
#   1. _prepare_request  - builds an HTTPRequest (method, url, headers, body)
#   2. io->call          - executes the request (pluggable: HTTP::Tiny, async, mock)
#   3. _check_response / _inflate_object / _inflate_list - processes the response
#
# This separation allows different IO backends (sync, async, mock) to slot in
# at step 2 without touching request preparation or response processing.
# ============================================================================

sub _prepare_request {
    my ($self, $method, $path, %opts) = @_;

    my $url = $self->server->endpoint . $path;
    my $content_type = $opts{content_type} // 'application/json';
    my $body = $opts{body};
    my $parameters = $opts{parameters};

    # Append query parameters to URL
    if ($parameters && %$parameters) {
        my @pairs;
        for my $key (sort keys %$parameters) {
            my $val = $parameters->{$key};
            push @pairs, "$key=$val" if defined $val;
        }
        if (@pairs) {
            $url .= ($url =~ /\?/ ? '&' : '?') . join('&', @pairs);
        }
    }

    return Kubernetes::REST::HTTPRequest->new(
        method => $method,
        url => $url,
        headers => {
            'Authorization' => 'Bearer ' . $self->credentials->token,
            'Content-Type' => $content_type,
            'Accept' => 'application/json',
        },
        ($body ? (content => $self->_json->encode($body)) : ()),
    );
}

sub _check_response {
    my ($self, $response, $context) = @_;
    if ($response->status >= 400) {
        croak "Kubernetes API error ($context): "
            . $response->status . " " . ($response->content // '');
    }
    return $response;
}

sub _inflate_object {
    my ($self, $class, $response) = @_;
    return $self->k8s->json_to_object($class, $response->content);
}

sub _inflate_list {
    my ($self, $class, $response) = @_;
    my $struct = $self->_json->decode($response->content);
    my @objects;
    for my $item (@{$struct->{items} // []}) {
        my $obj = eval { $self->k8s->struct_to_object($class, $item) };
        push @objects, $obj if $obj;
    }
    return IO::K8s::List->new(items => \@objects, item_class => $class);
}

sub _process_watch_chunk {
    my ($self, $class, $buffer_ref, $chunk) = @_;
    $$buffer_ref .= $chunk;

    my @events;
    while ($$buffer_ref =~ s/^([^\n]*)\n//) {
        my $line = $1;
        next unless length $line;

        my $data = eval { $self->_json->decode($line) };
        next unless $data;

        my $type = $data->{type} // '';
        my $raw_object = $data->{object} // {};

        # Track resourceVersion for resumability
        my $rv;
        if ($raw_object->{metadata} && $raw_object->{metadata}{resourceVersion}) {
            $rv = $raw_object->{metadata}{resourceVersion};
        }

        # Inflate the object (ERROR events stay as hashrefs)
        my $object;
        if ($type eq 'ERROR') {
            $object = $raw_object;
        } else {
            $object = eval { $self->k8s->struct_to_object($class, $raw_object) }
                // $raw_object;
        }

        push @events, {
            event => Kubernetes::REST::WatchEvent->new(
                type   => $type,
                object => $object,
                raw    => $raw_object,
            ),
            resourceVersion => $rv,
            is_error        => ($type eq 'ERROR' ? 1 : 0),
            error_code      => ($type eq 'ERROR' ? ($raw_object->{code} // 0) : 0),
        };
    }

    return @events;
}

# Convenience: prepare + call in one step (used by sync CRUD methods)
sub _request {
    my ($self, $method, $path, $body, %opts) = @_;
    my $req = $self->_prepare_request($method, $path,
        body => $body,
        %opts,
    );
    return $self->io->call($req);
}

sub list {
    my ($self, $short_class, %args) = @_;

    my $class = $self->expand_class($short_class);
    my $path = $self->_build_path($class, %args);
    my $response = $self->_request('GET', $path);
    $self->_check_response($response, "list $short_class");

    return $self->_inflate_list($class, $response);
}

sub get {
    my ($self, $short_class, @rest) = @_;

    # Support: get('Kind', 'name'), get('Kind', 'name', namespace => 'ns'),
    #          get('Kind', name => 'name'), get('Kind', name => 'name', namespace => 'ns')
    my %args;
    if (@rest == 1) {
        $args{name} = $rest[0];
    } elsif (@rest >= 2 && $rest[0] !~ /^(name|namespace)$/) {
        # First arg is name, rest are key=value pairs
        $args{name} = shift @rest;
        %args = (%args, @rest);
    } elsif (@rest % 2 == 0) {
        %args = @rest;
    } else {
        croak "Invalid arguments to get()";
    }

    my $class = $self->expand_class($short_class);
    croak "name required for get" unless $args{name};

    my $path = $self->_build_path($class, %args);
    my $response = $self->_request('GET', $path);
    $self->_check_response($response, "get $short_class");

    return $self->_inflate_object($class, $response);
}

sub create {
    my ($self, $object) = @_;

    my $class = ref($object);
    my $namespace = $object->can('metadata') && $object->metadata
        ? $object->metadata->namespace
        : undef;

    my $path = $self->_build_path($class, namespace => $namespace);
    my $response = $self->_request('POST', $path, $object->TO_JSON);
    $self->_check_response($response, "create " . ref($object));

    return $self->_inflate_object($class, $response);
}

sub update {
    my ($self, $object) = @_;

    my $class = ref($object);
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;

    my $path = $self->_build_path($class, name => $name, namespace => $namespace);
    my $response = $self->_request('PUT', $path, $object->TO_JSON);
    $self->_check_response($response, "update " . ref($object));

    return $self->_inflate_object($class, $response);
}

my %PATCH_TYPES = (
    strategic => 'application/strategic-merge-patch+json',
    merge     => 'application/merge-patch+json',
    json      => 'application/json-patch+json',
);

sub patch {
    my ($self, $class_or_object, @rest) = @_;

    my ($class, $name, $namespace, $patch, $patch_type);

    if (ref($class_or_object) && blessed($class_or_object)) {
        # Object passed: patch($object, patch => {...})
        my $object = $class_or_object;
        $class = ref($object);
        my $metadata = $object->metadata or croak "object must have metadata";
        $name = $metadata->name or croak "object must have metadata.name";
        $namespace = $metadata->namespace;
        my %args = @rest;
        $patch = $args{patch} // croak "patch requires 'patch' parameter";
        $patch_type = $args{type} // 'strategic';
    } else {
        # Class + name: patch('Pod', 'name', namespace => 'ns', patch => {...})
        my %args;
        if (@rest >= 1 && !ref($rest[0]) && $rest[0] !~ /^(name|namespace|patch|type)$/) {
            $args{name} = shift @rest;
            %args = (%args, @rest);
        } elsif (@rest % 2 == 0) {
            %args = @rest;
        } else {
            croak "Invalid arguments to patch()";
        }

        $class = $self->expand_class($class_or_object);
        $name = $args{name} or croak "name required for patch";
        $namespace = $args{namespace};
        $patch = $args{patch} // croak "patch requires 'patch' parameter";
        $patch_type = $args{type} // 'strategic';
    }

    my $content_type = $PATCH_TYPES{$patch_type}
        // croak "Unknown patch type '$patch_type' (use: strategic, merge, json)";

    my $path = $self->_build_path($class, name => $name, namespace => $namespace);
    my $response = $self->_request('PATCH', $path, $patch,
        content_type => $content_type);
    $self->_check_response($response, "patch $class");

    return $self->_inflate_object($class, $response);
}

sub delete {
    my ($self, $class_or_object, @rest) = @_;

    my ($class, $name, $namespace);

    if (ref($class_or_object)) {
        # Object passed
        my $object = $class_or_object;
        $class = ref($object);
        my $metadata = $object->metadata or croak "object must have metadata";
        $name = $metadata->name or croak "object must have metadata.name";
        $namespace = $metadata->namespace;
    } else {
        # Support: delete('Kind', 'name'), delete('Kind', 'name', namespace => 'ns'),
        #          delete('Kind', name => 'name'), delete('Kind', name => 'name', namespace => 'ns')
        my %args;
        if (@rest == 1) {
            $args{name} = $rest[0];
        } elsif (@rest >= 2 && $rest[0] !~ /^(name|namespace)$/) {
            # First arg is name, rest are key=value pairs
            $args{name} = shift @rest;
            %args = (%args, @rest);
        } elsif (@rest % 2 == 0) {
            %args = @rest;
        } else {
            croak "Invalid arguments to delete()";
        }

        $class = $self->expand_class($class_or_object);
        $name = $args{name} or croak "name required for delete";
        $namespace = $args{namespace};
    }

    my $path = $self->_build_path($class, name => $name, namespace => $namespace);
    my $response = $self->_request('DELETE', $path);
    $self->_check_response($response, "delete $class");

    return 1;
}

sub watch {
    my ($self, $short_class, %args) = @_;

    my $on_event = delete $args{on_event}
        or croak "watch requires 'on_event' callback";
    my $timeout          = delete $args{timeout} // 300;
    my $resource_version = delete $args{resourceVersion};
    my $label_selector   = delete $args{labelSelector};
    my $field_selector   = delete $args{fieldSelector};

    my $class = $self->expand_class($short_class);
    my $path = $self->_build_path($class, %args);

    my %params = (
        watch          => 'true',
        timeoutSeconds => $timeout,
    );
    $params{resourceVersion} = $resource_version if defined $resource_version;
    $params{labelSelector}   = $label_selector   if defined $label_selector;
    $params{fieldSelector}   = $field_selector   if defined $field_selector;

    my $req = $self->_prepare_request('GET', $path, parameters => \%params);

    my $buffer = '';
    my $last_rv = $resource_version;
    my $got_410 = 0;

    my $data_callback = sub {
        my ($chunk) = @_;
        for my $result ($self->_process_watch_chunk($class, \$buffer, $chunk)) {
            $last_rv = $result->{resourceVersion} if $result->{resourceVersion};
            $got_410 = 1 if $result->{error_code} == 410;
            $on_event->($result->{event});
        }
    };

    my $response = $self->io->call_streaming($req, $data_callback);

    $self->_check_response($response, "watch $short_class");

    croak "Watch expired (410 Gone): resourceVersion too old, re-list to get a fresh resourceVersion"
        if $got_410;

    return $last_rv;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Kubernetes::REST - A Perl REST Client for the Kubernetes API

=head1 SYNOPSIS

    use Kubernetes::REST;

    my $api = Kubernetes::REST->new(
        server => {
            endpoint => 'https://kubernetes.local:6443',
            ssl_verify_server => 1,
            ssl_ca_file => '/path/to/ca.crt',
        },
        credentials => { token => $token },
    );

    # List all namespaces
    my $namespaces = $api->list('Namespace');
    for my $ns ($namespaces->items->@*) {
        say $ns->metadata->name;
    }

    # List pods in a namespace
    my $pods = $api->list('Pod', namespace => 'default');

    # Get a specific pod
    my $pod = $api->get('Pod', name => 'my-pod', namespace => 'default');

    # Create a namespace
    my $ns = $api->new_object(Namespace => {
        metadata => { name => 'my-namespace' },
    });
    my $created = $api->create($ns);

    # Create multiple namespaces
    for my $i (1..10) {
        $api->create($api->new_object(Namespace =>
            metadata => { name => "test-ns-$i" },
        ));
    }

    # Update a resource (full replacement)
    $pod->metadata->labels({ app => 'updated' });
    my $updated = $api->update($pod);

    # Patch a resource (partial update)
    my $patched = $api->patch('Pod', 'my-pod',
        namespace => 'default',
        patch     => { metadata => { labels => { env => 'staging' } } },
    );

    # Delete a resource
    $api->delete($pod);
    # or by name:
    $api->delete('Pod', name => 'my-pod', namespace => 'default');

=head1 DESCRIPTION

This module provides a simple REST client for the Kubernetes API using IO::K8s
resource classes. The IO::K8s classes know their own metadata (API version,
kind, whether they're namespaced), so URL building is automatic.

=head1 UPGRADING FROM 0.02

B<WARNING: Version 1.00 contains breaking changes!>

This version has been completely rewritten. Key changes that may affect your code:

=over 4

=item * B<New simplified API>

The old method-per-operation API (e.g., C<< $api->Core->ListNamespacedPod(...) >>)
has been replaced with a simple API: C<list>, C<get>, C<create>, C<update>,
C<patch>, C<delete>, C<watch>.

=item * B<Old API still works but deprecated>

The old API is still available for backwards compatibility but will emit deprecation
warnings. Set C<$ENV{HIDE_KUBERNETES_REST_V0_API_WARNING}> to suppress warnings.

=item * B<Uses IO::K8s classes>

Results are now returned as typed L<IO::K8s> objects instead of raw hashrefs.
Lists are returned as L<IO::K8s::List> objects.

B<Note:> L<IO::K8s> has also been completely rewritten (Moose to Moo, updated
to Kubernetes v1.31 API). See L<IO::K8s/"UPGRADING FROM 0.04"> for details.

=item * B<Short resource names>

You can now use short names like C<'Pod'> instead of full class paths. The
C<resource_map> attribute controls this mapping.

=item * B<Dynamic resource map>

Use C<resource_map_from_cluster =E<gt> 1> to load the resource map from the
cluster's OpenAPI spec, ensuring compatibility with any Kubernetes version.

=back

=head1 ATTRIBUTES

=head2 server

Required. Connection details for the Kubernetes API server. Can be a hashref or
a L<Kubernetes::REST::Server> object.

    server => { endpoint => 'https://kubernetes.local:6443' }

=head2 credentials

Required. Authentication credentials. Can be a hashref or a L<Kubernetes::REST::AuthToken>
object.

    credentials => { token => $bearer_token }

=head2 io

Optional. HTTP backend for making requests. Must consume the
L<Kubernetes::REST::Role::IO> role (i.e. implement C<call($req)> and
C<call_streaming($req, $callback)>). Defaults to L<Kubernetes::REST::HTTPTinyIO>.

To use an async event loop, provide your own IO backend:

    my $api = Kubernetes::REST->new(
        server      => ...,
        credentials => ...,
        io          => My::AsyncIO->new(loop => $loop),
    );

=head2 k8s

Optional. L<IO::K8s> instance configured with the same resource map as this client.
Automatically created when needed.

=head2 resource_map_from_cluster

Optional boolean. If true, loads the resource map dynamically from the cluster's
OpenAPI spec. Defaults to true (loads from cluster).

    resource_map_from_cluster => 1

=head2 resource_map

Optional hashref. Maps short resource names to IO::K8s class paths. By default
loads dynamically from the cluster (if C<resource_map_from_cluster> is true) or
uses L<IO::K8s> built-in map. Can be overridden for custom resources.

    resource_map => { MyResource => 'Custom::V1::MyResource' }

=head2 cluster_version

Read-only. The Kubernetes cluster version string (e.g., "v1.31.0"). Fetched
automatically from the /version endpoint when first accessed.

=head1 METHODS

=head2 new_object($class, \%attrs) or new_object($class, %attrs)

Create a new IO::K8s object. Accepts short class names (e.g., 'Pod', 'Namespace')
and either a hashref or a hash of attributes.

    # With hashref
    my $ns = $api->new_object(Namespace => { metadata => { name => 'foo' } });

    # With hash
    my $ns = $api->new_object(Namespace => metadata => { name => 'foo' });

=head2 list($class, %args)

List resources. Returns an L<IO::K8s::List>.

    my $pods = $api->list('Pod', namespace => 'default');

=head2 get($class, %args)

Get a single resource by name.

    my $pod = $api->get('Pod', name => 'my-pod', namespace => 'default');

=head2 create($object)

Create a resource from an IO::K8s object.

    my $created = $api->create($pod);

=head2 update($object)

Update an existing resource.

    my $updated = $api->update($pod);

=head2 patch($class_or_object, %args)

Partially update a resource. Unlike C<update()> which replaces the entire
object, C<patch()> only modifies the fields you specify.

    # Add a label (strategic merge patch - default)
    my $patched = $api->patch('Pod', 'my-pod',
        namespace => 'default',
        patch     => { metadata => { labels => { env => 'staging' } } },
    );

    # Same thing with an object reference
    my $patched = $api->patch($pod,
        patch => { metadata => { labels => { env => 'staging' } } },
    );

    # Explicit patch type
    my $patched = $api->patch('Deployment', 'my-app',
        namespace => 'default',
        type      => 'merge',
        patch     => { spec => { replicas => 5 } },
    );

B<Required arguments:>

=over 4

=item patch

A hashref (or arrayref for JSON Patch) describing the changes to apply.

=item name

The resource name (when using class name, not object reference).

=back

B<Optional arguments:>

=over 4

=item type

The patch strategy. One of:

=over 4

=item C<strategic> (default)

Strategic Merge Patch. The Kubernetes-native patch type that understands
array merge semantics (e.g., adding a container to a pod spec without
removing existing containers).

=item C<merge>

JSON Merge Patch (RFC 7396). Simple recursive merge where C<null> values
delete keys. Arrays are replaced entirely.

=item C<json>

JSON Patch (RFC 6902). An array of operations:

    patch => [
        { op => 'replace', path => '/spec/replicas', value => 3 },
        { op => 'add', path => '/metadata/labels/env', value => 'prod' },
    ]

=back

=item namespace

For namespaced resources, the namespace.

=back

Returns the full updated object from the server.

=head2 delete($class_or_object, %args)

Delete a resource.

    $api->delete($pod);
    $api->delete('Pod', name => 'my-pod', namespace => 'default');

=head2 watch($class, %args)

Watch for changes to resources. Uses the Kubernetes Watch API with chunked
transfer encoding to stream events. The call blocks until the server-side
timeout expires.

    my $last_rv = $api->watch('Pod',
        namespace       => 'default',
        on_event        => sub {
            my ($event) = @_;
            say $event->type;                    # ADDED, MODIFIED, DELETED
            say $event->object->metadata->name;  # inflated IO::K8s object
        },
        timeout         => 300,           # server-side timeout (default: 300)
        resourceVersion => '12345',       # resume from this version
        labelSelector   => 'app=web',     # optional label filter
        fieldSelector   => 'status.phase=Running',  # optional field filter
    );

    # $last_rv is the last resourceVersion seen - use it to resume watching

B<Required arguments:>

=over 4

=item on_event

Callback called for each watch event with a L<Kubernetes::REST::WatchEvent>
object.

=back

B<Optional arguments:>

=over 4

=item timeout

Server-side timeout in seconds (default: 300). The API server will close
the connection after this many seconds.

=item resourceVersion

Resume watching from a specific resource version. Use the return value from
a previous C<watch()> call to avoid missing events.

=item labelSelector

Filter by label selector (e.g., C<'app=web,env=prod'>).

=item fieldSelector

Filter by field selector (e.g., C<'status.phase=Running'>).

=item namespace

For namespaced resources, the namespace to watch.

=back

B<Resumable watch pattern:>

    my $rv;
    while (1) {
        $rv = eval {
            $api->watch('Pod',
                namespace       => 'default',
                resourceVersion => $rv,
                on_event        => \&handle_event,
            );
        };
        if ($@ && $@ =~ /410 Gone/) {
            # resourceVersion expired, re-list to get fresh version
            my $list = $api->list('Pod', namespace => 'default');
            $rv = undef;  # start fresh
        }
    }

Returns the last C<resourceVersion> seen. Croaks on 410 Gone with a
message to re-list.

=head2 fetch_resource_map()

Fetch the resource map from the cluster's OpenAPI spec (/openapi/v2 endpoint).
Returns a hashref mapping short resource names (e.g., "Pod") to full IO::K8s
class paths. This method is called automatically if C<resource_map_from_cluster>
is enabled.

=head1 PLUGGABLE IO ARCHITECTURE

The HTTP transport is decoupled from request preparation and response
processing. This makes it possible to swap L<HTTP::Tiny> for an async
backend (e.g. L<Net::Async::HTTP>) without changing any API logic.

The pipeline for each API call:

    1. _prepare_request()    - builds HTTPRequest (method, url, headers, body)
    2. io->call()            - executes request (pluggable backend)
    3. _check_response()     - validates HTTP status
    4. _inflate_object/list  - decodes JSON + inflates IO::K8s objects

For watch, step 2 uses C<io-E<gt>call_streaming()> and step 4 uses
C<_process_watch_chunk()> which parses NDJSON and inflates each event.

To implement a custom IO backend, consume L<Kubernetes::REST::Role::IO>
and implement C<call($req)> and C<call_streaming($req, $callback)>.
See L<Kubernetes::REST::HTTPTinyIO> for the reference implementation.

=head1 SEE ALSO

L<Kubernetes::REST::WatchEvent>, L<Kubernetes::REST::Role::IO>,
L<Kubernetes::REST::HTTPTinyIO>, L<IO::K8s>,
L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/>

=cut
