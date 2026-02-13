package Kubernetes::REST::Core;
our $VERSION = '1.001';
# ABSTRACT: DEPRECATED - v0 API group for Core resources
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Core' });

=head1 SYNOPSIS

    # DEPRECATED API - use the new v1 API instead

    # Old way (deprecated):
    my $pods = $api->Core->ListNamespacedPod(namespace => 'default');

    # New way:
    my $pods = $api->list('Pod', namespace => 'default');

=head1 DESCRIPTION

B<This module is DEPRECATED>. It provides backwards compatibility for the v0 API (Kubernetes::REST 0.01/0.02 by JLMARTIN) which used method names like C<< $api->Core->ListNamespacedPod(...) >>.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->list('Pod', ...)
    $api->get('Pod', 'name', ...)
    $api->create($pod)
    $api->update($pod)
    $api->delete($pod)

All calls to this module emit deprecation warnings unless C<$ENV{HIDE_KUBERNETES_REST_V0_API_WARNING}> is set.

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=seealso

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=cut

1;
