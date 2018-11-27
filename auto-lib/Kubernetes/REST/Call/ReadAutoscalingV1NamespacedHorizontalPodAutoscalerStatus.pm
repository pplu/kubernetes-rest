package Kubernetes::REST::Call::ReadAutoscalingV1NamespacedHorizontalPodAutoscalerStatus;
  use Moo;
  

  

  sub _url_params { [
  
  ] }

  sub _query_params { [
  
  ] }

  sub _url { '/apis/autoscaling/v1/namespaces/{namespace}/horizontalpodautoscalers/{name}/status' }
  sub _method { 'GET' }
1;
