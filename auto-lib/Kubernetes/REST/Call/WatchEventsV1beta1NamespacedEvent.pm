package Kubernetes::REST::Call::WatchEventsV1beta1NamespacedEvent;
  use Moo;
  

  

  sub _url_params { [
  
  ] }

  sub _query_params { [
  
  ] }

  sub _url { '/apis/events.k8s.io/v1beta1/watch/namespaces/{namespace}/events/{name}' }
  sub _method { 'GET' }
1;