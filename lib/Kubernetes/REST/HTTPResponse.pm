package Kubernetes::REST::HTTPResponse;
our $VERSION = '1.002';
# ABSTRACT: HTTP response object
use Moo;
use Types::Standard qw/Str Int/;

=head1 SYNOPSIS

    use Kubernetes::REST::HTTPResponse;

    my $res = Kubernetes::REST::HTTPResponse->new(
        status => 200,
        content => '{"items":[]}',
    );

=head1 DESCRIPTION

Internal HTTP response object used by L<Kubernetes::REST>.

=cut

has content => (is => 'ro', isa => Str);

=attr content

The response body content.

=cut

has status => (is => 'ro', isa => Int);

=attr status

The HTTP status code (e.g., 200, 404, 500).

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST::HTTPRequest> - Request object

=item * L<Kubernetes::REST::Role::IO> - IO interface

=back

=cut
