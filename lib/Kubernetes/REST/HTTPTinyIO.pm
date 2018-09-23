package Kubernetes::REST::HTTPTinyIO;
  use Moo;
  use HTTP::Tiny;
  use Kubernetes::REST::HTTPResponse;

  has ua => (is => 'ro', default => sub {
    HTTP::Tiny->new(
      agent => 'Kubernetes::REST Perl Client ' . $Kubernetes::REST::VERSION,
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
