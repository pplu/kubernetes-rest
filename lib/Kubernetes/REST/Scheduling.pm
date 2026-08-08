package Kubernetes::REST::Scheduling;
our $VERSION = '1.107';
# ABSTRACT: Compatibility helper for deprecated v0 Scheduling calls
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Scheduling' });

=head1 SYNOPSIS

    # Old way (deprecated):
    my $pcs = $api->Scheduling->ListPriorityClass();

    # New way:
    my $pcs = $api->list('PriorityClass');

=head1 DESCRIPTION

This module keeps the deprecated v0 API usable. Kubernetes::REST 0.01/0.02 (by JLMARTIN) used method names like C<< $api->Scheduling->ListPriorityClass(...) >>; calls like that still reach the cluster from here, translated onto the v1 API.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->list('PriorityClass')
    $api->create($priorityclass)

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=seealso

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=cut

1;
