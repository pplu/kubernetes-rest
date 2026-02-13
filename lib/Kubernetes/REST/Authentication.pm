package Kubernetes::REST::Authentication;
our $VERSION = '1.001';
# ABSTRACT: DEPRECATED - v0 API group for Authentication resources
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Authentication' });

=head1 SYNOPSIS

    # DEPRECATED API - use the new v1 API instead

    # Old way (deprecated):
    my $result = $api->Authentication->CreateTokenReview(body => $tokenreview);

    # New way:
    my $result = $api->create($tokenreview);

=head1 DESCRIPTION

B<This module is DEPRECATED>. It provides backwards compatibility for the v0 API (Kubernetes::REST 0.01/0.02 by JLMARTIN) which used method names like C<< $api->Authentication->CreateTokenReview(...) >>.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->create($tokenreview)
    $api->create($tokenrequest)

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=seealso

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=cut

1;
