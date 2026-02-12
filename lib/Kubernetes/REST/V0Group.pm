package Kubernetes::REST::V0Group;
# ABSTRACT: Base class for backwards-compatible v0 API group wrappers
use Moo;
use Carp qw(croak carp);

has api => (is => 'ro', required => 1);
has group => (is => 'ro', required => 1);
has version => (is => 'ro', default => sub { 'v1' });

our $AUTOLOAD;

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    return if $method eq 'DESTROY';

    # Parse method name: ListNamespacedPod, ReadNamespacedPod, CreateNamespacedPod, etc.
    my ($action, $namespaced, $resource) = _parse_method($method);

    unless ($action && $resource) {
        croak "Unknown method: $method";
    }

    # Build class name
    my $class = $self->_build_class($resource);

    # Convert args to hash if needed
    my %params = @args == 1 && ref($args[0]) eq 'HASH' ? %{$args[0]} : @args;

    # Show deprecation warning
    $self->_warn_deprecated($method, $action, $class, \%params);

    # Call new API
    return $self->_dispatch($action, $class, \%params);
}

sub _parse_method {
    my ($method) = @_;

    # Patterns: List/Read/Create/Replace/Patch/Delete/Watch + Namespaced? + Resource + ForAllNamespaces?
    if ($method =~ /^(List|Read|Create|Replace|Patch|Delete|Watch)(Namespaced)?(\w+?)(ForAllNamespaces|Status)?$/) {
        my ($action, $namespaced, $resource, $suffix) = ($1, $2, $3, $4);
        $namespaced = 0 if $suffix && $suffix eq 'ForAllNamespaces';
        return (lc($action), $namespaced ? 1 : 0, $resource);
    }

    return (undef, undef, undef);
}

sub _build_class {
    my ($self, $resource) = @_;
    my $group = $self->group;
    my $version = ucfirst(lc($self->version));

    # Map group names to IO::K8s paths
    my %group_map = (
        Core => 'Core',
        Apps => 'Apps',
        Batch => 'Batch',
        Networking => 'Networking',
        Rbac => 'Rbac',
        Storage => 'Storage',
        Policy => 'Policy',
        Autoscaling => 'Autoscaling',
        Certificates => 'Certificates',
        Coordination => 'Coordination',
        Discovery => 'Discovery',
        Events => 'Events',
        Node => 'Node',
        Scheduling => 'Scheduling',
        Authentication => 'Authentication',
        Authorization => 'Authorization',
        Admissionregistration => 'Admissionregistration',
        Apiextensions => 'Apiextensions',
        RbacAuthorization => 'Rbac',
    );

    my $io_group = $group_map{$group} // $group;
    return "IO::K8s::Api::${io_group}::${version}::${resource}";
}

sub _warn_deprecated {
    my ($self, $method, $action, $class, $params) = @_;

    return if $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING};

    my $group = $self->group;
    my $new_call;

    if ($action eq 'list') {
        my $ns = $params->{namespace} ? ", namespace => '$params->{namespace}'" : '';
        $new_call = "\$api->list('$class'$ns)";
    } elsif ($action eq 'read') {
        my $ns = $params->{namespace} ? ", namespace => '$params->{namespace}'" : '';
        $new_call = "\$api->get('$class', name => '$params->{name}'$ns)";
    } elsif ($action eq 'create') {
        $new_call = "\$api->create(\$object)";
    } elsif ($action eq 'replace') {
        $new_call = "\$api->update(\$object)";
    } elsif ($action eq 'delete') {
        my $ns = $params->{namespace} ? ", namespace => '$params->{namespace}'" : '';
        $new_call = "\$api->delete('$class', name => '$params->{name}'$ns)";
    } else {
        $new_call = "\$api->$action('$class', ...)";
    }

    carp "Kubernetes::REST v0 API is deprecated: \$api->$group->$method(...) should be: $new_call";
}

sub _dispatch {
    my ($self, $action, $class, $params) = @_;
    my $api = $self->api;

    if ($action eq 'list') {
        return $api->list($class, %$params);
    } elsif ($action eq 'read') {
        return $api->get($class, %$params);
    } elsif ($action eq 'create') {
        # For create, we need the body object
        my $body = $params->{body} // croak "create requires 'body' parameter";
        return $api->create($body);
    } elsif ($action eq 'replace') {
        my $body = $params->{body} // croak "replace requires 'body' parameter";
        return $api->update($body);
    } elsif ($action eq 'delete') {
        return $api->delete($class, %$params);
    } elsif ($action eq 'patch') {
        croak "patch not yet implemented in new API";
    } elsif ($action eq 'watch') {
        croak "watch not yet implemented in new API";
    } else {
        croak "Unknown action: $action";
    }
}

# Prevent AUTOLOAD from being called for can()
sub can {
    my ($self, $method) = @_;
    return $self->SUPER::can($method) if $self->SUPER::can($method);
    # For v0 API methods, we always "can"
    my ($action, $namespaced, $resource) = _parse_method($method);
    return sub { $self->$method(@_) } if $action && $resource;
    return undef;
}

1;

=encoding UTF-8

=head1 NAME

Kubernetes::REST::V0Group - Base class for backwards-compatible v0 API group wrappers

=head1 SYNOPSIS

    # This API is deprecated - use the new API instead
    my $api = Kubernetes::REST->new(...);

    # Old way (deprecated):
    my $pods = $api->Core->ListNamespacedPod(namespace => 'default');

    # New way:
    my $pods = $api->list('Pod', namespace => 'default');

=head1 DESCRIPTION

This module provides backwards compatibility for the old v0 API that used method
names like C<ListNamespacedPod>, C<ReadNamespacedPod>, etc. It translates these
calls to the new simplified API.

B<This API is deprecated>. All calls emit deprecation warnings unless you set
C<$ENV{HIDE_KUBERNETES_REST_V0_API_WARNING}>.

=head1 METHODS

This module uses C<AUTOLOAD> to intercept method calls like C<ListNamespacedPod>
and translates them to the new API. The following actions are supported:

=over 4

=item * List -> list()

=item * Read -> get()

=item * Create -> create()

=item * Replace -> update()

=item * Delete -> delete()

=item * Patch -> not yet implemented

=item * Watch -> not yet implemented

=back

=head1 SEE ALSO

L<Kubernetes::REST>

=cut
