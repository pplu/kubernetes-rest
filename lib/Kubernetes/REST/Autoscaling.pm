package Kubernetes::REST::Autoscaling;
our $VERSION = '1.001';
# ABSTRACT: DEPRECATED - v0 API group for Autoscaling resources
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Autoscaling' });

=head1 SYNOPSIS

    # DEPRECATED API - use the new v1 API instead

    # Old way (deprecated):
    my $hpas = $api->Autoscaling->ListNamespacedHorizontalPodAutoscaler(namespace => 'default');

    # New way:
    my $hpas = $api->list('HorizontalPodAutoscaler', namespace => 'default');

=head1 DESCRIPTION

B<This module is DEPRECATED>. It provides backwards compatibility for the v0 API (Kubernetes::REST 0.01/0.02 by JLMARTIN) which used method names like C<< $api->Autoscaling->ListNamespacedHorizontalPodAutoscaler(...) >>.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->list('HorizontalPodAutoscaler', ...)
    $api->create($hpa)

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=seealso

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=cut

1;
