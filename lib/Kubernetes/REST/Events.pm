package Kubernetes::REST::Events;
our $VERSION = '1.108';
# ABSTRACT: Compatibility helper for deprecated v0 Events calls
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Events' });

=head1 SYNOPSIS

    # Old way (deprecated):
    my $events = $api->Events->ListNamespacedEvent(namespace => 'default');

    # New way:
    my $events = $api->list('Event', namespace => 'default');

=head1 DESCRIPTION

This module keeps the deprecated v0 API usable. Kubernetes::REST 0.01/0.02 (by JLMARTIN) used method names like C<< $api->Events->ListNamespacedEvent(...) >>; calls like that still reach the cluster from here, translated onto the v1 API.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->list('Event', ...)
    $api->create($event)

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=seealso

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=cut

1;
