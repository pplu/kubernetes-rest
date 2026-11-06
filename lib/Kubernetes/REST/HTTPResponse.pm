package Kubernetes::REST::HTTPResponse;
our $VERSION = '1.111';
# ABSTRACT: HTTP response object
use Moo;
use Types::Standard qw/Str Int HashRef ArrayRef/;

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

The response body content, as bytes: an IO backend must undo
C<Content-Encoding> (e.g. gzip) but leave the charset alone, and never decode
it itself. See L<Kubernetes::REST::Role::IO/Encoding contract>.

=cut

has status => (is => 'ro', isa => Int);

=attr status

The HTTP status code (e.g., 200, 404, 500). C<599> is the exception: it is
not a status of the API server but how an IO backend reports a transport
failure, with the error message as C<content>. See
L<Kubernetes::REST::Role::IO/Error contract>.

=cut

# The response headers, keyed by lowercased name, each an arrayref of that
# header's values in the order they came - a repeated Warning header gives
# several (karr k79). Optional: a backend that does not fill it gives none.
has headers => (is => 'ro', isa => HashRef[ArrayRef[Str]], default => sub { {} });

=attr headers

The response headers: a hashref keyed by lowercased header name, each value an
arrayref of that header's values in the order they came, so a repeated
C<Warning> header gives several. Values are bytes, like L</content>. Defaults
to C<{}>.

Optional for an IO backend, but without it the client sees no C<Warning>
headers and L<Kubernetes::REST/on_warning> is never called. See
L<Kubernetes::REST::Role::IO/Response headers>.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::HTTPRequest> - Request object

=item * L<Kubernetes::REST::Role::IO> - IO interface

=back

=cut
