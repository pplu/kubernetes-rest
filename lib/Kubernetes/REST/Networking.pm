package Kubernetes::REST::Networking;
our $VERSION = '1.001';
# ABSTRACT: DEPRECATED - v0 API group for Networking resources
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Networking' });

=head1 SYNOPSIS

    # DEPRECATED API - use the new v1 API instead

    # Old way (deprecated):
    my $ingresses = $api->Networking->ListNamespacedIngress(namespace => 'default');

    # New way:
    my $ingresses = $api->list('Ingress', namespace => 'default');

=head1 DESCRIPTION

B<This module is DEPRECATED>. It provides backwards compatibility for the v0 API (Kubernetes::REST 0.01/0.02 by JLMARTIN) which used method names like C<< $api->Networking->ListNamespacedIngress(...) >>.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->list('Ingress', ...)
    $api->list('NetworkPolicy', ...)
    $api->create($ingress)

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=seealso

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=cut

1;
