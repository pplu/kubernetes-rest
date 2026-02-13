package Kubernetes::REST::RbacAuthorization;
# ABSTRACT: DEPRECATED - v0 API group for RBAC resources
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'RbacAuthorization' });

=head1 SYNOPSIS

    # DEPRECATED API - use the new v1 API instead

    # Old way (deprecated):
    my $roles = $api->RbacAuthorization->ListNamespacedRole(namespace => 'default');

    # New way:
    my $roles = $api->list('Role', namespace => 'default');

=head1 DESCRIPTION

B<This module is DEPRECATED>. It provides backwards compatibility for the v0 API (Kubernetes::REST 0.01/0.02 by JLMARTIN) which used method names like C<< $api->RbacAuthorization->ListNamespacedRole(...) >>.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->list('Role', ...)
    $api->list('RoleBinding', ...)
    $api->list('ClusterRole')
    $api->create($role)

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=seealso

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=cut

1;
