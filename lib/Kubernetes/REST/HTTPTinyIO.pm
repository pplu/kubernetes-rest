package Kubernetes::REST::HTTPTinyIO;
  use Moo;
  use HTTP::Tiny;
  use IO::Socket::SSL;
  use Kubernetes::REST::HTTPResponse;
  use Types::Standard qw/Bool/;

  has ssl_verify_server => (is => 'ro', isa => Bool, default => 1);
  has ssl_cert_file => (is => 'ro');
  has ssl_key_file => (is => 'ro');
  has ssl_ca_file => (is => 'ro');

  has ua => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;

    my %options;
    $options{ SSL_verify_mode } = SSL_VERIFY_PEER if ($self->ssl_verify_server);
    $options{ SSL_cert_file } = $self->ssl_cert_file if (defined $self->ssl_cert_file);
    $options{ SSL_key_file } = $self->ssl_key_file if (defined $self->ssl_key_file);
    $options{ SSL_ca_file } = $self->ssl_ca_file if (defined $self->ssl_ca_file);
  
    return HTTP::Tiny->new(
      agent => 'Kubernetes::REST Perl Client ' . ($Kubernetes::REST::VERSION // 'dev'),
      SSL_options => \%options,
    );
  });

  sub call {
    my ($self, $call, $req) = @_;

    $req->authenticate if (defined $req->credentials);

    my $res = $self->ua->request(
      $req->method,
      $req->url,
      {
        headers => $req->headers,
        (defined $req->content) ? (content => $req->content) : (),
      }
    );

    return Kubernetes::REST::HTTPResponse->new(
       status => $res->{ status },
       (defined $res->{ content })?( content => $res->{ content } ) : (),
    );
  }

1;

=encoding UTF-8

=head1 NAME

Kubernetes::REST::HTTPTinyIO - HTTP client using HTTP::Tiny

=head1 SYNOPSIS

    use Kubernetes::REST::HTTPTinyIO;

    my $io = Kubernetes::REST::HTTPTinyIO->new(
        ssl_verify_server => 1,
        ssl_ca_file => '/path/to/ca.crt',
    );

=head1 DESCRIPTION

HTTP client implementation using L<HTTP::Tiny> for making Kubernetes API requests.

=attr ssl_verify_server

Boolean. Whether to verify the server's SSL certificate. Defaults to true.

=attr ssl_cert_file

Optional. Path to client certificate file for mTLS authentication.

=attr ssl_key_file

Optional. Path to client key file for mTLS authentication.

=attr ssl_ca_file

Optional. Path to CA certificate file for verifying the server certificate.

=method call($call, $req)

Execute an HTTP request. Returns a L<Kubernetes::REST::HTTPResponse>.

=cut
