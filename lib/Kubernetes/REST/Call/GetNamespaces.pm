package Kubernetes::REST::Call::GetNamespaces;
  use Moo;

  sub _url { '/api/v1/namespaces' }
  sub _method { 'GET' }
1;
