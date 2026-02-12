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

sub _request {
    my ($self, $method, $path, $body) = @_;

    my $url = $self->server->endpoint . $path;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => $method,
        url => $url,
        headers => {
            'Authorization' => 'Bearer ' . $self->credentials->token,
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
        },
        ($body ? (content => $self->_json->encode($body)) : ()),
    );

    return $self->io->call(undef, $req);
}

sub list {
    my ($self, $short_class, %args) = @_;

    my $class = $self->expand_class($short_class);
    my $path = $self->_build_path($class, %args);
    my $response = $self->_request('GET', $path);

    if ($response->status >= 400) {
        croak "Kubernetes API error: " . $response->status . " " . ($response->content // '');
    }

    my $struct = $self->_json->decode($response->content);
    my @objects;
    for my $item (@{$struct->{items} // []}) {
        my $obj = eval { $self->k8s->struct_to_object($class, $item) };
        push @objects, $obj if $obj;
    }

    return IO::K8s::List->new(items => \@objects, item_class => $class);
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

    if ($response->status >= 400) {
        croak "Kubernetes API error: " . $response->status . " " . ($response->content // '');
    }

    return $self->k8s->json_to_object($class, $response->content);
}

sub create {
    my ($self, $object) = @_;

    my $class = ref($object);
    my $namespace = $object->can('metadata') && $object->metadata
        ? $object->metadata->namespace
        : undef;

    my $path = $self->_build_path($class, namespace => $namespace);
    my $response = $self->_request('POST', $path, $object->TO_JSON);

    if ($response->status >= 400) {
        croak "Kubernetes API error: " . $response->status . " " . ($response->content // '');
    }

    return $self->k8s->json_to_object($class, $response->content);
}

sub update {
    my ($self, $object) = @_;

    my $class = ref($object);
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;

    my $path = $self->_build_path($class, name => $name, namespace => $namespace);
    my $response = $self->_request('PUT', $path, $object->TO_JSON);

    if ($response->status >= 400) {
        croak "Kubernetes API error: " . $response->status . " " . ($response->content // '');
    }

    return $self->k8s->json_to_object($class, $response->content);
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

    if ($response->status >= 400) {
        croak "Kubernetes API error: " . $response->status . " " . ($response->content // '');
    }

    return 1;
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

    # Update a resource
    $pod->metadata->labels({ app => 'updated' });
    my $updated = $api->update($pod);

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
has been replaced with a simple CRUD API: C<list>, C<get>, C<create>, C<update>,
C<delete>.

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

Optional. HTTP client for making requests. Defaults to L<Kubernetes::REST::HTTPTinyIO>.

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

=head2 delete($class_or_object, %args)

Delete a resource.

    $api->delete($pod);
    $api->delete('Pod', name => 'my-pod', namespace => 'default');

=head2 fetch_resource_map()

Fetch the resource map from the cluster's OpenAPI spec (/openapi/v2 endpoint).
Returns a hashref mapping short resource names (e.g., "Pod") to full IO::K8s
class paths. This method is called automatically if C<resource_map_from_cluster>
is enabled.

=head1 SEE ALSO

L<IO::K8s>, L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/>

=cut
