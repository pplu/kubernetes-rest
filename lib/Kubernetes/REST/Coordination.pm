package Kubernetes::REST::Coordination;
our $VERSION = '1.001';
# ABSTRACT: DEPRECATED - v0 API group for Coordination resources
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Coordination' });

=head1 SYNOPSIS

    # DEPRECATED API - use the new v1 API instead

    # Old way (deprecated):
    my $leases = $api->Coordination->ListNamespacedLease(namespace => 'kube-node-lease');

    # New way:
    my $leases = $api->list('Lease', namespace => 'kube-node-lease');

=head1 DESCRIPTION

B<This module is DEPRECATED>. It provides backwards compatibility for the v0 API (Kubernetes::REST 0.01/0.02 by JLMARTIN) which used method names like C<< $api->Coordination->ListNamespacedLease(...) >>.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->list('Lease', ...)
    $api->create($lease)

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=seealso

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=cut

1;
