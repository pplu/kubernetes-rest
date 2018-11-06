package Kubernetes::REST::Call::GetNamespace;
  use Moo;
  use Types::Standard qw/Str/;

  has name => (is => 'ro', isa => Str, required => 1);

  sub _url_params { [
    { name => 'name' },
  ] }

  sub _url { '/api/v1/namespaces/{name}' }
  sub _method { 'GET' }
1;
