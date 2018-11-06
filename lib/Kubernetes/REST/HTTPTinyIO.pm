package Kubernetes::REST::HTTPTinyIO;
  use Moo;
  use HTTP::Tiny;
  use IO::Socket::SSL;
  use Kubernetes::REST::HTTPResponse;

  has ua => (is => 'ro', default => sub {
    HTTP::Tiny->new(
      agent => 'Kubernetes::REST Perl Client ' . $Kubernetes::REST::VERSION,
      SSL_options => {
        SSL_cert_file => "$ENV{HOME}/.minikube/client.crt",
        SSL_key_file => "$ENV{HOME}/.minikube/client.key",
        SSL_verify_mode => SSL_VERIFY_PEER,
        SSL_ca_file => "$ENV{HOME}/.minikube/ca.crt",
      },
    );
  });

  sub call {
    my ($self, $req) = @_;

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
