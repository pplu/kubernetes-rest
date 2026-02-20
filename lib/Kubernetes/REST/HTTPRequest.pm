package Kubernetes::REST::HTTPRequest;
our $VERSION = '1.002';
# ABSTRACT: HTTP request object
use Moo;
use Types::Standard qw/Str HashRef/;

=head1 SYNOPSIS

    use Kubernetes::REST::HTTPRequest;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'GET',
        url => 'https://kubernetes.local:6443/api/v1/pods',
        headers => { 'Authorization' => 'Bearer token' },
    );

=head1 DESCRIPTION

Internal HTTP request object used by L<Kubernetes::REST>.

=cut

has server => (is => 'ro');

=attr server

Optional. L<Kubernetes::REST::Server> instance for building the full URL.

=cut

has credentials => (is => 'ro');

=attr credentials

Optional. L<Kubernetes::REST::AuthToken> instance for authentication.

=cut

sub authenticate {
    my $self = shift;
    my $auth = $self->credentials;
    if (defined $auth) {
      $self->headers->{ Authorization } = 'Bearer ' . $auth->token;
    }
}

=method authenticate

Add authentication header from the C<credentials> attribute.

=cut

has uri => (is => 'rw', isa => Str);

=attr uri

The URI path (e.g., C</api/v1/pods>).

=cut

has method => (is => 'rw', isa => Str);

=attr method

The HTTP method (GET, POST, PUT, DELETE, PATCH, etc.).

=cut

has url => (is => 'rw', isa => Str, lazy => 1, default => sub {
    my $self = shift;
    return $self->server->endpoint . $self->uri if $self->server;
    return '';
});

=attr url

The complete URL. If not provided, constructed from C<server> and C<uri>.

=cut

has headers => (is => 'rw', isa => HashRef, default => sub { {} });

=attr headers

Hashref of HTTP headers.

=cut

has parameters => (is => 'rw', isa => HashRef);

=attr parameters

Hashref of query parameters.

=cut

has content => (is => 'rw', isa => Str);

=attr content

The request body content (typically JSON).

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST::HTTPResponse> - Response object

=item * L<Kubernetes::REST::Role::IO> - IO interface

=back

=cut
