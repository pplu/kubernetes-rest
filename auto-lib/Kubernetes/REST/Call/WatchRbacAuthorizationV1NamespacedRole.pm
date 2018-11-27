package Kubernetes::REST::Call::WatchRbacAuthorizationV1NamespacedRole;
  use Moo;
  

  

  sub _url_params { [
  
  ] }

  sub _query_params { [
  
  ] }

  sub _url { '/apis/rbac.authorization.k8s.io/v1/watch/namespaces/{namespace}/roles/{name}' }
  sub _method { 'GET' }
1;
