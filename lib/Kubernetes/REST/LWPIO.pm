package Kubernetes::REST::LWPIO;
our $VERSION = '1.001';
# ABSTRACT: HTTP client using LWP::UserAgent
use Moo;
use LWP::UserAgent;
use Kubernetes::REST::HTTPResponse;
use Types::Standard qw/Bool/;

with 'Kubernetes::REST::Role::IO';

=head1 SYNOPSIS

    use Kubernetes::REST::LWPIO;

    my $io = Kubernetes::REST::LWPIO->new(
        ssl_verify_server => 1,
        ssl_ca_file => '/path/to/ca.crt',
    );

    # Access the LWP::UserAgent for debugging (e.g. with LWP::ConsoleLogger)
    use LWP::ConsoleLogger::Easy qw(debug_ua);
    debug_ua($io->ua);

=head1 DESCRIPTION

HTTP client implementation using L<LWP::UserAgent> for making Kubernetes API requests. This is the default IO backend for L<Kubernetes::REST>.

The C<ua> attribute is exposed so that debugging tools like L<LWP::ConsoleLogger> can be attached to inspect HTTP traffic.

=cut

has ssl_verify_server => (is => 'ro', isa => Bool, default => 1);

=attr ssl_verify_server

Boolean. Whether to verify the server's SSL certificate. Defaults to true.

=cut

has ssl_cert_file => (is => 'ro');

=attr ssl_cert_file

Optional. Path to client certificate file for mTLS authentication.

=cut

has ssl_key_file => (is => 'ro');

=attr ssl_key_file

Optional. Path to client key file for mTLS authentication.

=cut

has ssl_ca_file => (is => 'ro');

=attr ssl_ca_file

Optional. Path to CA certificate file for verifying the server certificate.

=cut

has timeout => (is => 'ro', default => sub { 310 });

=attr timeout

Timeout in seconds for HTTP requests. Defaults to 310 (slightly more than the Kubernetes default watch timeout of 300s).

=cut

has ua => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;

    my %ssl_opts;
    $ssl_opts{ verify_hostname } = $self->ssl_verify_server;
    $ssl_opts{ SSL_verify_mode } = $self->ssl_verify_server ? 1 : 0;
    $ssl_opts{ SSL_cert_file } = $self->ssl_cert_file if defined $self->ssl_cert_file;
    $ssl_opts{ SSL_key_file } = $self->ssl_key_file if defined $self->ssl_key_file;
    $ssl_opts{ SSL_ca_file } = $self->ssl_ca_file if defined $self->ssl_ca_file;

    return LWP::UserAgent->new(
      agent => 'Kubernetes::REST Perl Client ' . ($Kubernetes::REST::VERSION // 'dev'),
      timeout => $self->timeout,
      ssl_opts => \%ssl_opts,
    );
});

=attr ua

The underlying L<LWP::UserAgent> instance. Access this to attach middleware such as L<LWP::ConsoleLogger> for HTTP debugging.

=cut

sub call {
    my ($self, $req) = @_;

=method call

    my $response = $io->call($req);

Execute an HTTP request. Receives a fully prepared L<Kubernetes::REST::HTTPRequest> (URL, headers, content all set). Returns a L<Kubernetes::REST::HTTPResponse>.

=cut

    my $http_req = HTTP::Request->new(
      $req->method,
      $req->url,
      [ %{$req->headers} ],
      $req->content,
    );

    my $res = $self->ua->request($http_req);

    return Kubernetes::REST::HTTPResponse->new(
       status => $res->code,
       (length $res->decoded_content) ? ( content => $res->decoded_content ) : (),
    );
  }

sub call_streaming {
    my ($self, $req, $data_callback) = @_;

=method call_streaming

    my $response = $io->call_streaming($req, sub { my ($chunk) = @_; ... });

Execute an HTTP request with streaming response. The C<$data_callback> is called with each chunk of data as it arrives.

Used internally by L<Kubernetes::REST/watch> for the Watch API.

=cut

    my $http_req = HTTP::Request->new(
      $req->method,
      $req->url,
      [ %{$req->headers} ],
    );

    my $res = $self->ua->request($http_req, sub {
      my ($chunk) = @_;
      $data_callback->($chunk);
    });

    return Kubernetes::REST::HTTPResponse->new(
       status => $res->code,
       (length $res->decoded_content) ? ( content => $res->decoded_content ) : (),
    );
  }

1;

=seealso

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::Role::IO> - IO interface role

=item * L<Kubernetes::REST::HTTPTinyIO> - Alternative HTTP::Tiny backend

=item * L<LWP::ConsoleLogger> - HTTP debugging tool

=back

=cut
