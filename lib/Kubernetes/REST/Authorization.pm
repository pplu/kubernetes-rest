package Kubernetes::REST::Authorization;
our $VERSION = '1.108';
# ABSTRACT: Compatibility helper for deprecated v0 Authorization calls
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Authorization' });

=head1 SYNOPSIS

    # Old way (deprecated):
    my $result = $api->Authorization->CreateSelfSubjectAccessReview(body => $sar);

    # New way:
    my $result = $api->create($sar);

=head1 DESCRIPTION

This module keeps the deprecated v0 API usable. Kubernetes::REST 0.01/0.02 (by JLMARTIN) used method names like C<< $api->Authorization->CreateSelfSubjectAccessReview(...) >>; calls like that still reach the cluster from here, translated onto the v1 API.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->create($selfsubjectaccessreview)
    $api->create($subjectaccessreview)

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=seealso

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=cut

1;
