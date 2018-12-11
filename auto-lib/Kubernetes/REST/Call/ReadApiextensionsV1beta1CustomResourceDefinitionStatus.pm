package Kubernetes::REST::Call::ReadApiextensionsV1beta1CustomResourceDefinitionStatus;
  use Moo;
  use Types::Standard qw/Str/;

  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has pretty => (is => 'ro', isa => Str);
  

  sub _url_params { [
  
    { name => 'name' },
  
  ] }

  sub _query_params { [
  
    { name => 'pretty' },
  
  ] }

  sub _url { '/apis/apiextensions.k8s.io/v1beta1/customresourcedefinitions/{name}/status' }
  sub _method { 'GET' }
1;
