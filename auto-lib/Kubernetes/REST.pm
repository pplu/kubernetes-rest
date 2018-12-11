package Kubernetes::REST;
  use Moo;
  use Types::Standard qw/HasMethods Str InstanceOf/;
  use Kubernetes::REST::CallContext;
  use Kubernetes::REST::Server;

  our $VERSION = '0.01';

  has param_converter => (is => 'ro', isa => HasMethods['params2request'], default => sub {
    require Kubernetes::REST::ListToRequest;
    Kubernetes::REST::ListToRequest->new;  
  });
  has io => (is => 'ro', isa => HasMethods['call'], lazy => 1, default => sub {
    my $self = shift;
    require Kubernetes::REST::HTTPTinyIO;
    Kubernetes::REST::HTTPTinyIO->new(
      ssl_verify_server => $self->server->ssl_verify_server,
      ssl_cert_file => $self->server->ssl_cert_file,
      ssl_key_file => $self->server->ssl_key_file,
      ssl_ca_file => $self->server->ssl_ca_file,
    );
  });
  has result_parser => (is => 'ro', isa => HasMethods['result2return'], default => sub {
    require Kubernetes::REST::Result2Hash;
    Kubernetes::REST::Result2Hash->new
  });

  has server => (
    is => 'ro',
    isa => InstanceOf['Kubernetes::REST::Server'], 
    required => 1,
    coerce => sub {
      Kubernetes::REST::Server->new(@_);
    },
  );
  #TODO: decide the interface for the credentials object. For now, it if has a token method,
  #      it will use it
  has credentials => (is => 'ro', required => 1);

  sub _invoke {
    my ($self, $method, $params) = @_;
    my $call = Kubernetes::REST::CallContext->new(
      method => $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub ConnectCoreV1DeleteNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1DeleteNamespacedPodProxy', \@params);
  }
  
  sub ConnectCoreV1DeleteNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1DeleteNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1DeleteNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1DeleteNamespacedServiceProxy', \@params);
  }
  
  sub ConnectCoreV1DeleteNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1DeleteNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1DeleteNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1DeleteNodeProxy', \@params);
  }
  
  sub ConnectCoreV1DeleteNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1DeleteNodeProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1GetNamespacedPodAttach {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1GetNamespacedPodAttach', \@params);
  }
  
  sub ConnectCoreV1GetNamespacedPodExec {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1GetNamespacedPodExec', \@params);
  }
  
  sub ConnectCoreV1GetNamespacedPodPortforward {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1GetNamespacedPodPortforward', \@params);
  }
  
  sub ConnectCoreV1GetNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1GetNamespacedPodProxy', \@params);
  }
  
  sub ConnectCoreV1GetNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1GetNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1GetNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1GetNamespacedServiceProxy', \@params);
  }
  
  sub ConnectCoreV1GetNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1GetNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1GetNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1GetNodeProxy', \@params);
  }
  
  sub ConnectCoreV1GetNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1GetNodeProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1HeadNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1HeadNamespacedPodProxy', \@params);
  }
  
  sub ConnectCoreV1HeadNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1HeadNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1HeadNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1HeadNamespacedServiceProxy', \@params);
  }
  
  sub ConnectCoreV1HeadNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1HeadNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1HeadNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1HeadNodeProxy', \@params);
  }
  
  sub ConnectCoreV1HeadNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1HeadNodeProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1OptionsNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1OptionsNamespacedPodProxy', \@params);
  }
  
  sub ConnectCoreV1OptionsNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1OptionsNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1OptionsNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1OptionsNamespacedServiceProxy', \@params);
  }
  
  sub ConnectCoreV1OptionsNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1OptionsNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1OptionsNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1OptionsNodeProxy', \@params);
  }
  
  sub ConnectCoreV1OptionsNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1OptionsNodeProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1PatchNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PatchNamespacedPodProxy', \@params);
  }
  
  sub ConnectCoreV1PatchNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PatchNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1PatchNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PatchNamespacedServiceProxy', \@params);
  }
  
  sub ConnectCoreV1PatchNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PatchNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1PatchNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PatchNodeProxy', \@params);
  }
  
  sub ConnectCoreV1PatchNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PatchNodeProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1PostNamespacedPodAttach {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PostNamespacedPodAttach', \@params);
  }
  
  sub ConnectCoreV1PostNamespacedPodExec {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PostNamespacedPodExec', \@params);
  }
  
  sub ConnectCoreV1PostNamespacedPodPortforward {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PostNamespacedPodPortforward', \@params);
  }
  
  sub ConnectCoreV1PostNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PostNamespacedPodProxy', \@params);
  }
  
  sub ConnectCoreV1PostNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PostNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1PostNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PostNamespacedServiceProxy', \@params);
  }
  
  sub ConnectCoreV1PostNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PostNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1PostNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PostNodeProxy', \@params);
  }
  
  sub ConnectCoreV1PostNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PostNodeProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1PutNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PutNamespacedPodProxy', \@params);
  }
  
  sub ConnectCoreV1PutNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PutNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1PutNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PutNamespacedServiceProxy', \@params);
  }
  
  sub ConnectCoreV1PutNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PutNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectCoreV1PutNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PutNodeProxy', \@params);
  }
  
  sub ConnectCoreV1PutNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke('ConnectCoreV1PutNodeProxyWithPath', \@params);
  }
  
  sub CreateAdmissionregistrationV1alpha1InitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('CreateAdmissionregistrationV1alpha1InitializerConfiguration', \@params);
  }
  
  sub CreateAdmissionregistrationV1beta1MutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('CreateAdmissionregistrationV1beta1MutatingWebhookConfiguration', \@params);
  }
  
  sub CreateAdmissionregistrationV1beta1ValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('CreateAdmissionregistrationV1beta1ValidatingWebhookConfiguration', \@params);
  }
  
  sub CreateApiextensionsV1beta1CustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke('CreateApiextensionsV1beta1CustomResourceDefinition', \@params);
  }
  
  sub CreateApiregistrationV1APIService {
    my ($self, @params) = @_;
    $self->_invoke('CreateApiregistrationV1APIService', \@params);
  }
  
  sub CreateApiregistrationV1beta1APIService {
    my ($self, @params) = @_;
    $self->_invoke('CreateApiregistrationV1beta1APIService', \@params);
  }
  
  sub CreateAppsV1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1NamespacedControllerRevision', \@params);
  }
  
  sub CreateAppsV1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1NamespacedDaemonSet', \@params);
  }
  
  sub CreateAppsV1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1NamespacedDeployment', \@params);
  }
  
  sub CreateAppsV1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1NamespacedReplicaSet', \@params);
  }
  
  sub CreateAppsV1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1NamespacedStatefulSet', \@params);
  }
  
  sub CreateAppsV1beta1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1beta1NamespacedControllerRevision', \@params);
  }
  
  sub CreateAppsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1beta1NamespacedDeployment', \@params);
  }
  
  sub CreateAppsV1beta1NamespacedDeploymentRollback {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1beta1NamespacedDeploymentRollback', \@params);
  }
  
  sub CreateAppsV1beta1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1beta1NamespacedStatefulSet', \@params);
  }
  
  sub CreateAppsV1beta2NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1beta2NamespacedControllerRevision', \@params);
  }
  
  sub CreateAppsV1beta2NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1beta2NamespacedDaemonSet', \@params);
  }
  
  sub CreateAppsV1beta2NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1beta2NamespacedDeployment', \@params);
  }
  
  sub CreateAppsV1beta2NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1beta2NamespacedReplicaSet', \@params);
  }
  
  sub CreateAppsV1beta2NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('CreateAppsV1beta2NamespacedStatefulSet', \@params);
  }
  
  sub CreateAuditregistrationV1alpha1AuditSink {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuditregistrationV1alpha1AuditSink', \@params);
  }
  
  sub CreateAuthenticationV1TokenReview {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuthenticationV1TokenReview', \@params);
  }
  
  sub CreateAuthenticationV1beta1TokenReview {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuthenticationV1beta1TokenReview', \@params);
  }
  
  sub CreateAuthorizationV1NamespacedLocalSubjectAccessReview {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuthorizationV1NamespacedLocalSubjectAccessReview', \@params);
  }
  
  sub CreateAuthorizationV1SelfSubjectAccessReview {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuthorizationV1SelfSubjectAccessReview', \@params);
  }
  
  sub CreateAuthorizationV1SelfSubjectRulesReview {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuthorizationV1SelfSubjectRulesReview', \@params);
  }
  
  sub CreateAuthorizationV1SubjectAccessReview {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuthorizationV1SubjectAccessReview', \@params);
  }
  
  sub CreateAuthorizationV1beta1NamespacedLocalSubjectAccessReview {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuthorizationV1beta1NamespacedLocalSubjectAccessReview', \@params);
  }
  
  sub CreateAuthorizationV1beta1SelfSubjectAccessReview {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuthorizationV1beta1SelfSubjectAccessReview', \@params);
  }
  
  sub CreateAuthorizationV1beta1SelfSubjectRulesReview {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuthorizationV1beta1SelfSubjectRulesReview', \@params);
  }
  
  sub CreateAuthorizationV1beta1SubjectAccessReview {
    my ($self, @params) = @_;
    $self->_invoke('CreateAuthorizationV1beta1SubjectAccessReview', \@params);
  }
  
  sub CreateAutoscalingV1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('CreateAutoscalingV1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub CreateAutoscalingV2beta1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('CreateAutoscalingV2beta1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub CreateAutoscalingV2beta2NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('CreateAutoscalingV2beta2NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub CreateBatchV1NamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke('CreateBatchV1NamespacedJob', \@params);
  }
  
  sub CreateBatchV1beta1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('CreateBatchV1beta1NamespacedCronJob', \@params);
  }
  
  sub CreateBatchV2alpha1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('CreateBatchV2alpha1NamespacedCronJob', \@params);
  }
  
  sub CreateCertificatesV1beta1CertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke('CreateCertificatesV1beta1CertificateSigningRequest', \@params);
  }
  
  sub CreateCoordinationV1beta1NamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoordinationV1beta1NamespacedLease', \@params);
  }
  
  sub CreateCoreV1Namespace {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1Namespace', \@params);
  }
  
  sub CreateCoreV1NamespacedBinding {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedBinding', \@params);
  }
  
  sub CreateCoreV1NamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedConfigMap', \@params);
  }
  
  sub CreateCoreV1NamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedEndpoints', \@params);
  }
  
  sub CreateCoreV1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedEvent', \@params);
  }
  
  sub CreateCoreV1NamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedLimitRange', \@params);
  }
  
  sub CreateCoreV1NamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedPersistentVolumeClaim', \@params);
  }
  
  sub CreateCoreV1NamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedPod', \@params);
  }
  
  sub CreateCoreV1NamespacedPodBinding {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedPodBinding', \@params);
  }
  
  sub CreateCoreV1NamespacedPodEviction {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedPodEviction', \@params);
  }
  
  sub CreateCoreV1NamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedPodTemplate', \@params);
  }
  
  sub CreateCoreV1NamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedReplicationController', \@params);
  }
  
  sub CreateCoreV1NamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedResourceQuota', \@params);
  }
  
  sub CreateCoreV1NamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedSecret', \@params);
  }
  
  sub CreateCoreV1NamespacedService {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedService', \@params);
  }
  
  sub CreateCoreV1NamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1NamespacedServiceAccount', \@params);
  }
  
  sub CreateCoreV1Node {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1Node', \@params);
  }
  
  sub CreateCoreV1PersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke('CreateCoreV1PersistentVolume', \@params);
  }
  
  sub CreateEventsV1beta1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('CreateEventsV1beta1NamespacedEvent', \@params);
  }
  
  sub CreateExtensionsV1beta1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('CreateExtensionsV1beta1NamespacedDaemonSet', \@params);
  }
  
  sub CreateExtensionsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('CreateExtensionsV1beta1NamespacedDeployment', \@params);
  }
  
  sub CreateExtensionsV1beta1NamespacedDeploymentRollback {
    my ($self, @params) = @_;
    $self->_invoke('CreateExtensionsV1beta1NamespacedDeploymentRollback', \@params);
  }
  
  sub CreateExtensionsV1beta1NamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke('CreateExtensionsV1beta1NamespacedIngress', \@params);
  }
  
  sub CreateExtensionsV1beta1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('CreateExtensionsV1beta1NamespacedNetworkPolicy', \@params);
  }
  
  sub CreateExtensionsV1beta1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('CreateExtensionsV1beta1NamespacedReplicaSet', \@params);
  }
  
  sub CreateExtensionsV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('CreateExtensionsV1beta1PodSecurityPolicy', \@params);
  }
  
  sub CreateNetworkingV1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('CreateNetworkingV1NamespacedNetworkPolicy', \@params);
  }
  
  sub CreatePolicyV1beta1NamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke('CreatePolicyV1beta1NamespacedPodDisruptionBudget', \@params);
  }
  
  sub CreatePolicyV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('CreatePolicyV1beta1PodSecurityPolicy', \@params);
  }
  
  sub CreateRbacAuthorizationV1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1ClusterRole', \@params);
  }
  
  sub CreateRbacAuthorizationV1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1ClusterRoleBinding', \@params);
  }
  
  sub CreateRbacAuthorizationV1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1NamespacedRole', \@params);
  }
  
  sub CreateRbacAuthorizationV1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1NamespacedRoleBinding', \@params);
  }
  
  sub CreateRbacAuthorizationV1alpha1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1alpha1ClusterRole', \@params);
  }
  
  sub CreateRbacAuthorizationV1alpha1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1alpha1ClusterRoleBinding', \@params);
  }
  
  sub CreateRbacAuthorizationV1alpha1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1alpha1NamespacedRole', \@params);
  }
  
  sub CreateRbacAuthorizationV1alpha1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1alpha1NamespacedRoleBinding', \@params);
  }
  
  sub CreateRbacAuthorizationV1beta1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1beta1ClusterRole', \@params);
  }
  
  sub CreateRbacAuthorizationV1beta1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1beta1ClusterRoleBinding', \@params);
  }
  
  sub CreateRbacAuthorizationV1beta1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1beta1NamespacedRole', \@params);
  }
  
  sub CreateRbacAuthorizationV1beta1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('CreateRbacAuthorizationV1beta1NamespacedRoleBinding', \@params);
  }
  
  sub CreateSchedulingV1alpha1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('CreateSchedulingV1alpha1PriorityClass', \@params);
  }
  
  sub CreateSchedulingV1beta1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('CreateSchedulingV1beta1PriorityClass', \@params);
  }
  
  sub CreateSettingsV1alpha1NamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke('CreateSettingsV1alpha1NamespacedPodPreset', \@params);
  }
  
  sub CreateStorageV1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('CreateStorageV1StorageClass', \@params);
  }
  
  sub CreateStorageV1alpha1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('CreateStorageV1alpha1VolumeAttachment', \@params);
  }
  
  sub CreateStorageV1beta1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('CreateStorageV1beta1StorageClass', \@params);
  }
  
  sub CreateStorageV1beta1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('CreateStorageV1beta1VolumeAttachment', \@params);
  }
  
  sub DeleteAdmissionregistrationV1alpha1CollectionInitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAdmissionregistrationV1alpha1CollectionInitializerConfiguration', \@params);
  }
  
  sub DeleteAdmissionregistrationV1alpha1InitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAdmissionregistrationV1alpha1InitializerConfiguration', \@params);
  }
  
  sub DeleteAdmissionregistrationV1beta1CollectionMutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAdmissionregistrationV1beta1CollectionMutatingWebhookConfiguration', \@params);
  }
  
  sub DeleteAdmissionregistrationV1beta1CollectionValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAdmissionregistrationV1beta1CollectionValidatingWebhookConfiguration', \@params);
  }
  
  sub DeleteAdmissionregistrationV1beta1MutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAdmissionregistrationV1beta1MutatingWebhookConfiguration', \@params);
  }
  
  sub DeleteAdmissionregistrationV1beta1ValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAdmissionregistrationV1beta1ValidatingWebhookConfiguration', \@params);
  }
  
  sub DeleteApiextensionsV1beta1CollectionCustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke('DeleteApiextensionsV1beta1CollectionCustomResourceDefinition', \@params);
  }
  
  sub DeleteApiextensionsV1beta1CustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke('DeleteApiextensionsV1beta1CustomResourceDefinition', \@params);
  }
  
  sub DeleteApiregistrationV1APIService {
    my ($self, @params) = @_;
    $self->_invoke('DeleteApiregistrationV1APIService', \@params);
  }
  
  sub DeleteApiregistrationV1CollectionAPIService {
    my ($self, @params) = @_;
    $self->_invoke('DeleteApiregistrationV1CollectionAPIService', \@params);
  }
  
  sub DeleteApiregistrationV1beta1APIService {
    my ($self, @params) = @_;
    $self->_invoke('DeleteApiregistrationV1beta1APIService', \@params);
  }
  
  sub DeleteApiregistrationV1beta1CollectionAPIService {
    my ($self, @params) = @_;
    $self->_invoke('DeleteApiregistrationV1beta1CollectionAPIService', \@params);
  }
  
  sub DeleteAppsV1CollectionNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1CollectionNamespacedControllerRevision', \@params);
  }
  
  sub DeleteAppsV1CollectionNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1CollectionNamespacedDaemonSet', \@params);
  }
  
  sub DeleteAppsV1CollectionNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1CollectionNamespacedDeployment', \@params);
  }
  
  sub DeleteAppsV1CollectionNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1CollectionNamespacedReplicaSet', \@params);
  }
  
  sub DeleteAppsV1CollectionNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1CollectionNamespacedStatefulSet', \@params);
  }
  
  sub DeleteAppsV1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1NamespacedControllerRevision', \@params);
  }
  
  sub DeleteAppsV1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1NamespacedDaemonSet', \@params);
  }
  
  sub DeleteAppsV1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1NamespacedDeployment', \@params);
  }
  
  sub DeleteAppsV1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1NamespacedReplicaSet', \@params);
  }
  
  sub DeleteAppsV1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1NamespacedStatefulSet', \@params);
  }
  
  sub DeleteAppsV1beta1CollectionNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta1CollectionNamespacedControllerRevision', \@params);
  }
  
  sub DeleteAppsV1beta1CollectionNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta1CollectionNamespacedDeployment', \@params);
  }
  
  sub DeleteAppsV1beta1CollectionNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta1CollectionNamespacedStatefulSet', \@params);
  }
  
  sub DeleteAppsV1beta1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta1NamespacedControllerRevision', \@params);
  }
  
  sub DeleteAppsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta1NamespacedDeployment', \@params);
  }
  
  sub DeleteAppsV1beta1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta1NamespacedStatefulSet', \@params);
  }
  
  sub DeleteAppsV1beta2CollectionNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta2CollectionNamespacedControllerRevision', \@params);
  }
  
  sub DeleteAppsV1beta2CollectionNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta2CollectionNamespacedDaemonSet', \@params);
  }
  
  sub DeleteAppsV1beta2CollectionNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta2CollectionNamespacedDeployment', \@params);
  }
  
  sub DeleteAppsV1beta2CollectionNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta2CollectionNamespacedReplicaSet', \@params);
  }
  
  sub DeleteAppsV1beta2CollectionNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta2CollectionNamespacedStatefulSet', \@params);
  }
  
  sub DeleteAppsV1beta2NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta2NamespacedControllerRevision', \@params);
  }
  
  sub DeleteAppsV1beta2NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta2NamespacedDaemonSet', \@params);
  }
  
  sub DeleteAppsV1beta2NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta2NamespacedDeployment', \@params);
  }
  
  sub DeleteAppsV1beta2NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta2NamespacedReplicaSet', \@params);
  }
  
  sub DeleteAppsV1beta2NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAppsV1beta2NamespacedStatefulSet', \@params);
  }
  
  sub DeleteAuditregistrationV1alpha1AuditSink {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAuditregistrationV1alpha1AuditSink', \@params);
  }
  
  sub DeleteAuditregistrationV1alpha1CollectionAuditSink {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAuditregistrationV1alpha1CollectionAuditSink', \@params);
  }
  
  sub DeleteAutoscalingV1CollectionNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAutoscalingV1CollectionNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub DeleteAutoscalingV1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAutoscalingV1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub DeleteAutoscalingV2beta1CollectionNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAutoscalingV2beta1CollectionNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub DeleteAutoscalingV2beta1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAutoscalingV2beta1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub DeleteAutoscalingV2beta2CollectionNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAutoscalingV2beta2CollectionNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub DeleteAutoscalingV2beta2NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('DeleteAutoscalingV2beta2NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub DeleteBatchV1CollectionNamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke('DeleteBatchV1CollectionNamespacedJob', \@params);
  }
  
  sub DeleteBatchV1NamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke('DeleteBatchV1NamespacedJob', \@params);
  }
  
  sub DeleteBatchV1beta1CollectionNamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('DeleteBatchV1beta1CollectionNamespacedCronJob', \@params);
  }
  
  sub DeleteBatchV1beta1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('DeleteBatchV1beta1NamespacedCronJob', \@params);
  }
  
  sub DeleteBatchV2alpha1CollectionNamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('DeleteBatchV2alpha1CollectionNamespacedCronJob', \@params);
  }
  
  sub DeleteBatchV2alpha1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('DeleteBatchV2alpha1NamespacedCronJob', \@params);
  }
  
  sub DeleteCertificatesV1beta1CertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCertificatesV1beta1CertificateSigningRequest', \@params);
  }
  
  sub DeleteCertificatesV1beta1CollectionCertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCertificatesV1beta1CollectionCertificateSigningRequest', \@params);
  }
  
  sub DeleteCoordinationV1beta1CollectionNamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoordinationV1beta1CollectionNamespacedLease', \@params);
  }
  
  sub DeleteCoordinationV1beta1NamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoordinationV1beta1NamespacedLease', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedConfigMap', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedEndpoints', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedEvent', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedLimitRange', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedPersistentVolumeClaim', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedPod', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedPodTemplate', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedReplicationController', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedResourceQuota', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedSecret', \@params);
  }
  
  sub DeleteCoreV1CollectionNamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNamespacedServiceAccount', \@params);
  }
  
  sub DeleteCoreV1CollectionNode {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionNode', \@params);
  }
  
  sub DeleteCoreV1CollectionPersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1CollectionPersistentVolume', \@params);
  }
  
  sub DeleteCoreV1Namespace {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1Namespace', \@params);
  }
  
  sub DeleteCoreV1NamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedConfigMap', \@params);
  }
  
  sub DeleteCoreV1NamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedEndpoints', \@params);
  }
  
  sub DeleteCoreV1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedEvent', \@params);
  }
  
  sub DeleteCoreV1NamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedLimitRange', \@params);
  }
  
  sub DeleteCoreV1NamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedPersistentVolumeClaim', \@params);
  }
  
  sub DeleteCoreV1NamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedPod', \@params);
  }
  
  sub DeleteCoreV1NamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedPodTemplate', \@params);
  }
  
  sub DeleteCoreV1NamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedReplicationController', \@params);
  }
  
  sub DeleteCoreV1NamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedResourceQuota', \@params);
  }
  
  sub DeleteCoreV1NamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedSecret', \@params);
  }
  
  sub DeleteCoreV1NamespacedService {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedService', \@params);
  }
  
  sub DeleteCoreV1NamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1NamespacedServiceAccount', \@params);
  }
  
  sub DeleteCoreV1Node {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1Node', \@params);
  }
  
  sub DeleteCoreV1PersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke('DeleteCoreV1PersistentVolume', \@params);
  }
  
  sub DeleteEventsV1beta1CollectionNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('DeleteEventsV1beta1CollectionNamespacedEvent', \@params);
  }
  
  sub DeleteEventsV1beta1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('DeleteEventsV1beta1NamespacedEvent', \@params);
  }
  
  sub DeleteExtensionsV1beta1CollectionNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1CollectionNamespacedDaemonSet', \@params);
  }
  
  sub DeleteExtensionsV1beta1CollectionNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1CollectionNamespacedDeployment', \@params);
  }
  
  sub DeleteExtensionsV1beta1CollectionNamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1CollectionNamespacedIngress', \@params);
  }
  
  sub DeleteExtensionsV1beta1CollectionNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1CollectionNamespacedNetworkPolicy', \@params);
  }
  
  sub DeleteExtensionsV1beta1CollectionNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1CollectionNamespacedReplicaSet', \@params);
  }
  
  sub DeleteExtensionsV1beta1CollectionPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1CollectionPodSecurityPolicy', \@params);
  }
  
  sub DeleteExtensionsV1beta1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1NamespacedDaemonSet', \@params);
  }
  
  sub DeleteExtensionsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1NamespacedDeployment', \@params);
  }
  
  sub DeleteExtensionsV1beta1NamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1NamespacedIngress', \@params);
  }
  
  sub DeleteExtensionsV1beta1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1NamespacedNetworkPolicy', \@params);
  }
  
  sub DeleteExtensionsV1beta1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1NamespacedReplicaSet', \@params);
  }
  
  sub DeleteExtensionsV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('DeleteExtensionsV1beta1PodSecurityPolicy', \@params);
  }
  
  sub DeleteNetworkingV1CollectionNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('DeleteNetworkingV1CollectionNamespacedNetworkPolicy', \@params);
  }
  
  sub DeleteNetworkingV1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('DeleteNetworkingV1NamespacedNetworkPolicy', \@params);
  }
  
  sub DeletePolicyV1beta1CollectionNamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke('DeletePolicyV1beta1CollectionNamespacedPodDisruptionBudget', \@params);
  }
  
  sub DeletePolicyV1beta1CollectionPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('DeletePolicyV1beta1CollectionPodSecurityPolicy', \@params);
  }
  
  sub DeletePolicyV1beta1NamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke('DeletePolicyV1beta1NamespacedPodDisruptionBudget', \@params);
  }
  
  sub DeletePolicyV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('DeletePolicyV1beta1PodSecurityPolicy', \@params);
  }
  
  sub DeleteRbacAuthorizationV1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1ClusterRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1ClusterRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1CollectionClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1CollectionClusterRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1CollectionClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1CollectionClusterRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1CollectionNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1CollectionNamespacedRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1CollectionNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1CollectionNamespacedRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1NamespacedRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1NamespacedRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1alpha1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1alpha1ClusterRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1alpha1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1alpha1ClusterRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1alpha1CollectionClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1alpha1CollectionClusterRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1alpha1CollectionClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1alpha1CollectionClusterRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1alpha1CollectionNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1alpha1CollectionNamespacedRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1alpha1CollectionNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1alpha1CollectionNamespacedRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1alpha1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1alpha1NamespacedRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1alpha1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1alpha1NamespacedRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1beta1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1beta1ClusterRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1beta1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1beta1ClusterRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1beta1CollectionClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1beta1CollectionClusterRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1beta1CollectionClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1beta1CollectionClusterRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1beta1CollectionNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1beta1CollectionNamespacedRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1beta1CollectionNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1beta1CollectionNamespacedRoleBinding', \@params);
  }
  
  sub DeleteRbacAuthorizationV1beta1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1beta1NamespacedRole', \@params);
  }
  
  sub DeleteRbacAuthorizationV1beta1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('DeleteRbacAuthorizationV1beta1NamespacedRoleBinding', \@params);
  }
  
  sub DeleteSchedulingV1alpha1CollectionPriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('DeleteSchedulingV1alpha1CollectionPriorityClass', \@params);
  }
  
  sub DeleteSchedulingV1alpha1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('DeleteSchedulingV1alpha1PriorityClass', \@params);
  }
  
  sub DeleteSchedulingV1beta1CollectionPriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('DeleteSchedulingV1beta1CollectionPriorityClass', \@params);
  }
  
  sub DeleteSchedulingV1beta1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('DeleteSchedulingV1beta1PriorityClass', \@params);
  }
  
  sub DeleteSettingsV1alpha1CollectionNamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke('DeleteSettingsV1alpha1CollectionNamespacedPodPreset', \@params);
  }
  
  sub DeleteSettingsV1alpha1NamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke('DeleteSettingsV1alpha1NamespacedPodPreset', \@params);
  }
  
  sub DeleteStorageV1CollectionStorageClass {
    my ($self, @params) = @_;
    $self->_invoke('DeleteStorageV1CollectionStorageClass', \@params);
  }
  
  sub DeleteStorageV1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('DeleteStorageV1StorageClass', \@params);
  }
  
  sub DeleteStorageV1alpha1CollectionVolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteStorageV1alpha1CollectionVolumeAttachment', \@params);
  }
  
  sub DeleteStorageV1alpha1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteStorageV1alpha1VolumeAttachment', \@params);
  }
  
  sub DeleteStorageV1beta1CollectionStorageClass {
    my ($self, @params) = @_;
    $self->_invoke('DeleteStorageV1beta1CollectionStorageClass', \@params);
  }
  
  sub DeleteStorageV1beta1CollectionVolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteStorageV1beta1CollectionVolumeAttachment', \@params);
  }
  
  sub DeleteStorageV1beta1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('DeleteStorageV1beta1StorageClass', \@params);
  }
  
  sub DeleteStorageV1beta1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('DeleteStorageV1beta1VolumeAttachment', \@params);
  }
  
  sub GetAPIVersions {
    my ($self, @params) = @_;
    $self->_invoke('GetAPIVersions', \@params);
  }
  
  sub GetAdmissionregistrationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetAdmissionregistrationAPIGroup', \@params);
  }
  
  sub GetAdmissionregistrationV1alpha1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAdmissionregistrationV1alpha1APIResources', \@params);
  }
  
  sub GetAdmissionregistrationV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAdmissionregistrationV1beta1APIResources', \@params);
  }
  
  sub GetApiextensionsAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetApiextensionsAPIGroup', \@params);
  }
  
  sub GetApiextensionsV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetApiextensionsV1beta1APIResources', \@params);
  }
  
  sub GetApiregistrationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetApiregistrationAPIGroup', \@params);
  }
  
  sub GetApiregistrationV1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetApiregistrationV1APIResources', \@params);
  }
  
  sub GetApiregistrationV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetApiregistrationV1beta1APIResources', \@params);
  }
  
  sub GetAppsAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetAppsAPIGroup', \@params);
  }
  
  sub GetAppsV1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAppsV1APIResources', \@params);
  }
  
  sub GetAppsV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAppsV1beta1APIResources', \@params);
  }
  
  sub GetAppsV1beta2APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAppsV1beta2APIResources', \@params);
  }
  
  sub GetAuditregistrationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetAuditregistrationAPIGroup', \@params);
  }
  
  sub GetAuditregistrationV1alpha1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAuditregistrationV1alpha1APIResources', \@params);
  }
  
  sub GetAuthenticationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetAuthenticationAPIGroup', \@params);
  }
  
  sub GetAuthenticationV1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAuthenticationV1APIResources', \@params);
  }
  
  sub GetAuthenticationV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAuthenticationV1beta1APIResources', \@params);
  }
  
  sub GetAuthorizationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetAuthorizationAPIGroup', \@params);
  }
  
  sub GetAuthorizationV1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAuthorizationV1APIResources', \@params);
  }
  
  sub GetAuthorizationV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAuthorizationV1beta1APIResources', \@params);
  }
  
  sub GetAutoscalingAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetAutoscalingAPIGroup', \@params);
  }
  
  sub GetAutoscalingV1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAutoscalingV1APIResources', \@params);
  }
  
  sub GetAutoscalingV2beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAutoscalingV2beta1APIResources', \@params);
  }
  
  sub GetAutoscalingV2beta2APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetAutoscalingV2beta2APIResources', \@params);
  }
  
  sub GetBatchAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetBatchAPIGroup', \@params);
  }
  
  sub GetBatchV1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetBatchV1APIResources', \@params);
  }
  
  sub GetBatchV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetBatchV1beta1APIResources', \@params);
  }
  
  sub GetBatchV2alpha1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetBatchV2alpha1APIResources', \@params);
  }
  
  sub GetCertificatesAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetCertificatesAPIGroup', \@params);
  }
  
  sub GetCertificatesV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetCertificatesV1beta1APIResources', \@params);
  }
  
  sub GetCodeVersion {
    my ($self, @params) = @_;
    $self->_invoke('GetCodeVersion', \@params);
  }
  
  sub GetCoordinationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetCoordinationAPIGroup', \@params);
  }
  
  sub GetCoordinationV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetCoordinationV1beta1APIResources', \@params);
  }
  
  sub GetCoreAPIVersions {
    my ($self, @params) = @_;
    $self->_invoke('GetCoreAPIVersions', \@params);
  }
  
  sub GetCoreV1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetCoreV1APIResources', \@params);
  }
  
  sub GetEventsAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetEventsAPIGroup', \@params);
  }
  
  sub GetEventsV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetEventsV1beta1APIResources', \@params);
  }
  
  sub GetExtensionsAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetExtensionsAPIGroup', \@params);
  }
  
  sub GetExtensionsV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetExtensionsV1beta1APIResources', \@params);
  }
  
  sub GetNetworkingAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetNetworkingAPIGroup', \@params);
  }
  
  sub GetNetworkingV1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetNetworkingV1APIResources', \@params);
  }
  
  sub GetPolicyAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetPolicyAPIGroup', \@params);
  }
  
  sub GetPolicyV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetPolicyV1beta1APIResources', \@params);
  }
  
  sub GetRbacAuthorizationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetRbacAuthorizationAPIGroup', \@params);
  }
  
  sub GetRbacAuthorizationV1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetRbacAuthorizationV1APIResources', \@params);
  }
  
  sub GetRbacAuthorizationV1alpha1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetRbacAuthorizationV1alpha1APIResources', \@params);
  }
  
  sub GetRbacAuthorizationV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetRbacAuthorizationV1beta1APIResources', \@params);
  }
  
  sub GetSchedulingAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetSchedulingAPIGroup', \@params);
  }
  
  sub GetSchedulingV1alpha1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetSchedulingV1alpha1APIResources', \@params);
  }
  
  sub GetSchedulingV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetSchedulingV1beta1APIResources', \@params);
  }
  
  sub GetSettingsAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetSettingsAPIGroup', \@params);
  }
  
  sub GetSettingsV1alpha1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetSettingsV1alpha1APIResources', \@params);
  }
  
  sub GetStorageAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke('GetStorageAPIGroup', \@params);
  }
  
  sub GetStorageV1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetStorageV1APIResources', \@params);
  }
  
  sub GetStorageV1alpha1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetStorageV1alpha1APIResources', \@params);
  }
  
  sub GetStorageV1beta1APIResources {
    my ($self, @params) = @_;
    $self->_invoke('GetStorageV1beta1APIResources', \@params);
  }
  
  sub ListAdmissionregistrationV1alpha1InitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('ListAdmissionregistrationV1alpha1InitializerConfiguration', \@params);
  }
  
  sub ListAdmissionregistrationV1beta1MutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('ListAdmissionregistrationV1beta1MutatingWebhookConfiguration', \@params);
  }
  
  sub ListAdmissionregistrationV1beta1ValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('ListAdmissionregistrationV1beta1ValidatingWebhookConfiguration', \@params);
  }
  
  sub ListApiextensionsV1beta1CustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke('ListApiextensionsV1beta1CustomResourceDefinition', \@params);
  }
  
  sub ListApiregistrationV1APIService {
    my ($self, @params) = @_;
    $self->_invoke('ListApiregistrationV1APIService', \@params);
  }
  
  sub ListApiregistrationV1beta1APIService {
    my ($self, @params) = @_;
    $self->_invoke('ListApiregistrationV1beta1APIService', \@params);
  }
  
  sub ListAppsV1ControllerRevisionForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1ControllerRevisionForAllNamespaces', \@params);
  }
  
  sub ListAppsV1DaemonSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1DaemonSetForAllNamespaces', \@params);
  }
  
  sub ListAppsV1DeploymentForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1DeploymentForAllNamespaces', \@params);
  }
  
  sub ListAppsV1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1NamespacedControllerRevision', \@params);
  }
  
  sub ListAppsV1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1NamespacedDaemonSet', \@params);
  }
  
  sub ListAppsV1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1NamespacedDeployment', \@params);
  }
  
  sub ListAppsV1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1NamespacedReplicaSet', \@params);
  }
  
  sub ListAppsV1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1NamespacedStatefulSet', \@params);
  }
  
  sub ListAppsV1ReplicaSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1ReplicaSetForAllNamespaces', \@params);
  }
  
  sub ListAppsV1StatefulSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1StatefulSetForAllNamespaces', \@params);
  }
  
  sub ListAppsV1beta1ControllerRevisionForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta1ControllerRevisionForAllNamespaces', \@params);
  }
  
  sub ListAppsV1beta1DeploymentForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta1DeploymentForAllNamespaces', \@params);
  }
  
  sub ListAppsV1beta1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta1NamespacedControllerRevision', \@params);
  }
  
  sub ListAppsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta1NamespacedDeployment', \@params);
  }
  
  sub ListAppsV1beta1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta1NamespacedStatefulSet', \@params);
  }
  
  sub ListAppsV1beta1StatefulSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta1StatefulSetForAllNamespaces', \@params);
  }
  
  sub ListAppsV1beta2ControllerRevisionForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta2ControllerRevisionForAllNamespaces', \@params);
  }
  
  sub ListAppsV1beta2DaemonSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta2DaemonSetForAllNamespaces', \@params);
  }
  
  sub ListAppsV1beta2DeploymentForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta2DeploymentForAllNamespaces', \@params);
  }
  
  sub ListAppsV1beta2NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta2NamespacedControllerRevision', \@params);
  }
  
  sub ListAppsV1beta2NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta2NamespacedDaemonSet', \@params);
  }
  
  sub ListAppsV1beta2NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta2NamespacedDeployment', \@params);
  }
  
  sub ListAppsV1beta2NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta2NamespacedReplicaSet', \@params);
  }
  
  sub ListAppsV1beta2NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta2NamespacedStatefulSet', \@params);
  }
  
  sub ListAppsV1beta2ReplicaSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta2ReplicaSetForAllNamespaces', \@params);
  }
  
  sub ListAppsV1beta2StatefulSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAppsV1beta2StatefulSetForAllNamespaces', \@params);
  }
  
  sub ListAuditregistrationV1alpha1AuditSink {
    my ($self, @params) = @_;
    $self->_invoke('ListAuditregistrationV1alpha1AuditSink', \@params);
  }
  
  sub ListAutoscalingV1HorizontalPodAutoscalerForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAutoscalingV1HorizontalPodAutoscalerForAllNamespaces', \@params);
  }
  
  sub ListAutoscalingV1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('ListAutoscalingV1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ListAutoscalingV2beta1HorizontalPodAutoscalerForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAutoscalingV2beta1HorizontalPodAutoscalerForAllNamespaces', \@params);
  }
  
  sub ListAutoscalingV2beta1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('ListAutoscalingV2beta1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ListAutoscalingV2beta2HorizontalPodAutoscalerForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListAutoscalingV2beta2HorizontalPodAutoscalerForAllNamespaces', \@params);
  }
  
  sub ListAutoscalingV2beta2NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('ListAutoscalingV2beta2NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ListBatchV1JobForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListBatchV1JobForAllNamespaces', \@params);
  }
  
  sub ListBatchV1NamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke('ListBatchV1NamespacedJob', \@params);
  }
  
  sub ListBatchV1beta1CronJobForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListBatchV1beta1CronJobForAllNamespaces', \@params);
  }
  
  sub ListBatchV1beta1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('ListBatchV1beta1NamespacedCronJob', \@params);
  }
  
  sub ListBatchV2alpha1CronJobForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListBatchV2alpha1CronJobForAllNamespaces', \@params);
  }
  
  sub ListBatchV2alpha1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('ListBatchV2alpha1NamespacedCronJob', \@params);
  }
  
  sub ListCertificatesV1beta1CertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke('ListCertificatesV1beta1CertificateSigningRequest', \@params);
  }
  
  sub ListCoordinationV1beta1LeaseForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoordinationV1beta1LeaseForAllNamespaces', \@params);
  }
  
  sub ListCoordinationV1beta1NamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke('ListCoordinationV1beta1NamespacedLease', \@params);
  }
  
  sub ListCoreV1ComponentStatus {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1ComponentStatus', \@params);
  }
  
  sub ListCoreV1ConfigMapForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1ConfigMapForAllNamespaces', \@params);
  }
  
  sub ListCoreV1EndpointsForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1EndpointsForAllNamespaces', \@params);
  }
  
  sub ListCoreV1EventForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1EventForAllNamespaces', \@params);
  }
  
  sub ListCoreV1LimitRangeForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1LimitRangeForAllNamespaces', \@params);
  }
  
  sub ListCoreV1Namespace {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1Namespace', \@params);
  }
  
  sub ListCoreV1NamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedConfigMap', \@params);
  }
  
  sub ListCoreV1NamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedEndpoints', \@params);
  }
  
  sub ListCoreV1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedEvent', \@params);
  }
  
  sub ListCoreV1NamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedLimitRange', \@params);
  }
  
  sub ListCoreV1NamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedPersistentVolumeClaim', \@params);
  }
  
  sub ListCoreV1NamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedPod', \@params);
  }
  
  sub ListCoreV1NamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedPodTemplate', \@params);
  }
  
  sub ListCoreV1NamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedReplicationController', \@params);
  }
  
  sub ListCoreV1NamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedResourceQuota', \@params);
  }
  
  sub ListCoreV1NamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedSecret', \@params);
  }
  
  sub ListCoreV1NamespacedService {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedService', \@params);
  }
  
  sub ListCoreV1NamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1NamespacedServiceAccount', \@params);
  }
  
  sub ListCoreV1Node {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1Node', \@params);
  }
  
  sub ListCoreV1PersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1PersistentVolume', \@params);
  }
  
  sub ListCoreV1PersistentVolumeClaimForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1PersistentVolumeClaimForAllNamespaces', \@params);
  }
  
  sub ListCoreV1PodForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1PodForAllNamespaces', \@params);
  }
  
  sub ListCoreV1PodTemplateForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1PodTemplateForAllNamespaces', \@params);
  }
  
  sub ListCoreV1ReplicationControllerForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1ReplicationControllerForAllNamespaces', \@params);
  }
  
  sub ListCoreV1ResourceQuotaForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1ResourceQuotaForAllNamespaces', \@params);
  }
  
  sub ListCoreV1SecretForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1SecretForAllNamespaces', \@params);
  }
  
  sub ListCoreV1ServiceAccountForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1ServiceAccountForAllNamespaces', \@params);
  }
  
  sub ListCoreV1ServiceForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListCoreV1ServiceForAllNamespaces', \@params);
  }
  
  sub ListEventsV1beta1EventForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListEventsV1beta1EventForAllNamespaces', \@params);
  }
  
  sub ListEventsV1beta1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('ListEventsV1beta1NamespacedEvent', \@params);
  }
  
  sub ListExtensionsV1beta1DaemonSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1DaemonSetForAllNamespaces', \@params);
  }
  
  sub ListExtensionsV1beta1DeploymentForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1DeploymentForAllNamespaces', \@params);
  }
  
  sub ListExtensionsV1beta1IngressForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1IngressForAllNamespaces', \@params);
  }
  
  sub ListExtensionsV1beta1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1NamespacedDaemonSet', \@params);
  }
  
  sub ListExtensionsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1NamespacedDeployment', \@params);
  }
  
  sub ListExtensionsV1beta1NamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1NamespacedIngress', \@params);
  }
  
  sub ListExtensionsV1beta1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1NamespacedNetworkPolicy', \@params);
  }
  
  sub ListExtensionsV1beta1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1NamespacedReplicaSet', \@params);
  }
  
  sub ListExtensionsV1beta1NetworkPolicyForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1NetworkPolicyForAllNamespaces', \@params);
  }
  
  sub ListExtensionsV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1PodSecurityPolicy', \@params);
  }
  
  sub ListExtensionsV1beta1ReplicaSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListExtensionsV1beta1ReplicaSetForAllNamespaces', \@params);
  }
  
  sub ListNetworkingV1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ListNetworkingV1NamespacedNetworkPolicy', \@params);
  }
  
  sub ListNetworkingV1NetworkPolicyForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListNetworkingV1NetworkPolicyForAllNamespaces', \@params);
  }
  
  sub ListPolicyV1beta1NamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke('ListPolicyV1beta1NamespacedPodDisruptionBudget', \@params);
  }
  
  sub ListPolicyV1beta1PodDisruptionBudgetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListPolicyV1beta1PodDisruptionBudgetForAllNamespaces', \@params);
  }
  
  sub ListPolicyV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ListPolicyV1beta1PodSecurityPolicy', \@params);
  }
  
  sub ListRbacAuthorizationV1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1ClusterRole', \@params);
  }
  
  sub ListRbacAuthorizationV1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1ClusterRoleBinding', \@params);
  }
  
  sub ListRbacAuthorizationV1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1NamespacedRole', \@params);
  }
  
  sub ListRbacAuthorizationV1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1NamespacedRoleBinding', \@params);
  }
  
  sub ListRbacAuthorizationV1RoleBindingForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1RoleBindingForAllNamespaces', \@params);
  }
  
  sub ListRbacAuthorizationV1RoleForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1RoleForAllNamespaces', \@params);
  }
  
  sub ListRbacAuthorizationV1alpha1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1alpha1ClusterRole', \@params);
  }
  
  sub ListRbacAuthorizationV1alpha1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1alpha1ClusterRoleBinding', \@params);
  }
  
  sub ListRbacAuthorizationV1alpha1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1alpha1NamespacedRole', \@params);
  }
  
  sub ListRbacAuthorizationV1alpha1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1alpha1NamespacedRoleBinding', \@params);
  }
  
  sub ListRbacAuthorizationV1alpha1RoleBindingForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1alpha1RoleBindingForAllNamespaces', \@params);
  }
  
  sub ListRbacAuthorizationV1alpha1RoleForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1alpha1RoleForAllNamespaces', \@params);
  }
  
  sub ListRbacAuthorizationV1beta1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1beta1ClusterRole', \@params);
  }
  
  sub ListRbacAuthorizationV1beta1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1beta1ClusterRoleBinding', \@params);
  }
  
  sub ListRbacAuthorizationV1beta1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1beta1NamespacedRole', \@params);
  }
  
  sub ListRbacAuthorizationV1beta1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1beta1NamespacedRoleBinding', \@params);
  }
  
  sub ListRbacAuthorizationV1beta1RoleBindingForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1beta1RoleBindingForAllNamespaces', \@params);
  }
  
  sub ListRbacAuthorizationV1beta1RoleForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListRbacAuthorizationV1beta1RoleForAllNamespaces', \@params);
  }
  
  sub ListSchedulingV1alpha1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('ListSchedulingV1alpha1PriorityClass', \@params);
  }
  
  sub ListSchedulingV1beta1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('ListSchedulingV1beta1PriorityClass', \@params);
  }
  
  sub ListSettingsV1alpha1NamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke('ListSettingsV1alpha1NamespacedPodPreset', \@params);
  }
  
  sub ListSettingsV1alpha1PodPresetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('ListSettingsV1alpha1PodPresetForAllNamespaces', \@params);
  }
  
  sub ListStorageV1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('ListStorageV1StorageClass', \@params);
  }
  
  sub ListStorageV1alpha1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('ListStorageV1alpha1VolumeAttachment', \@params);
  }
  
  sub ListStorageV1beta1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('ListStorageV1beta1StorageClass', \@params);
  }
  
  sub ListStorageV1beta1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('ListStorageV1beta1VolumeAttachment', \@params);
  }
  
  sub LogFileHandler {
    my ($self, @params) = @_;
    $self->_invoke('LogFileHandler', \@params);
  }
  
  sub LogFileListHandler {
    my ($self, @params) = @_;
    $self->_invoke('LogFileListHandler', \@params);
  }
  
  sub PatchAdmissionregistrationV1alpha1InitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('PatchAdmissionregistrationV1alpha1InitializerConfiguration', \@params);
  }
  
  sub PatchAdmissionregistrationV1beta1MutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('PatchAdmissionregistrationV1beta1MutatingWebhookConfiguration', \@params);
  }
  
  sub PatchAdmissionregistrationV1beta1ValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('PatchAdmissionregistrationV1beta1ValidatingWebhookConfiguration', \@params);
  }
  
  sub PatchApiextensionsV1beta1CustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke('PatchApiextensionsV1beta1CustomResourceDefinition', \@params);
  }
  
  sub PatchApiextensionsV1beta1CustomResourceDefinitionStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchApiextensionsV1beta1CustomResourceDefinitionStatus', \@params);
  }
  
  sub PatchApiregistrationV1APIService {
    my ($self, @params) = @_;
    $self->_invoke('PatchApiregistrationV1APIService', \@params);
  }
  
  sub PatchApiregistrationV1APIServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchApiregistrationV1APIServiceStatus', \@params);
  }
  
  sub PatchApiregistrationV1beta1APIService {
    my ($self, @params) = @_;
    $self->_invoke('PatchApiregistrationV1beta1APIService', \@params);
  }
  
  sub PatchApiregistrationV1beta1APIServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchApiregistrationV1beta1APIServiceStatus', \@params);
  }
  
  sub PatchAppsV1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedControllerRevision', \@params);
  }
  
  sub PatchAppsV1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedDaemonSet', \@params);
  }
  
  sub PatchAppsV1NamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedDaemonSetStatus', \@params);
  }
  
  sub PatchAppsV1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedDeployment', \@params);
  }
  
  sub PatchAppsV1NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedDeploymentScale', \@params);
  }
  
  sub PatchAppsV1NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedDeploymentStatus', \@params);
  }
  
  sub PatchAppsV1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedReplicaSet', \@params);
  }
  
  sub PatchAppsV1NamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedReplicaSetScale', \@params);
  }
  
  sub PatchAppsV1NamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedReplicaSetStatus', \@params);
  }
  
  sub PatchAppsV1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedStatefulSet', \@params);
  }
  
  sub PatchAppsV1NamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedStatefulSetScale', \@params);
  }
  
  sub PatchAppsV1NamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1NamespacedStatefulSetStatus', \@params);
  }
  
  sub PatchAppsV1beta1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta1NamespacedControllerRevision', \@params);
  }
  
  sub PatchAppsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta1NamespacedDeployment', \@params);
  }
  
  sub PatchAppsV1beta1NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta1NamespacedDeploymentScale', \@params);
  }
  
  sub PatchAppsV1beta1NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta1NamespacedDeploymentStatus', \@params);
  }
  
  sub PatchAppsV1beta1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta1NamespacedStatefulSet', \@params);
  }
  
  sub PatchAppsV1beta1NamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta1NamespacedStatefulSetScale', \@params);
  }
  
  sub PatchAppsV1beta1NamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta1NamespacedStatefulSetStatus', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedControllerRevision', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedDaemonSet', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedDaemonSetStatus', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedDeployment', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedDeploymentScale', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedDeploymentStatus', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedReplicaSet', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedReplicaSetScale', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedReplicaSetStatus', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedStatefulSet', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedStatefulSetScale', \@params);
  }
  
  sub PatchAppsV1beta2NamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAppsV1beta2NamespacedStatefulSetStatus', \@params);
  }
  
  sub PatchAuditregistrationV1alpha1AuditSink {
    my ($self, @params) = @_;
    $self->_invoke('PatchAuditregistrationV1alpha1AuditSink', \@params);
  }
  
  sub PatchAutoscalingV1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('PatchAutoscalingV1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub PatchAutoscalingV1NamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAutoscalingV1NamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub PatchAutoscalingV2beta1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('PatchAutoscalingV2beta1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub PatchAutoscalingV2beta1NamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAutoscalingV2beta1NamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub PatchAutoscalingV2beta2NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('PatchAutoscalingV2beta2NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub PatchAutoscalingV2beta2NamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchAutoscalingV2beta2NamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub PatchBatchV1NamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke('PatchBatchV1NamespacedJob', \@params);
  }
  
  sub PatchBatchV1NamespacedJobStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchBatchV1NamespacedJobStatus', \@params);
  }
  
  sub PatchBatchV1beta1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('PatchBatchV1beta1NamespacedCronJob', \@params);
  }
  
  sub PatchBatchV1beta1NamespacedCronJobStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchBatchV1beta1NamespacedCronJobStatus', \@params);
  }
  
  sub PatchBatchV2alpha1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('PatchBatchV2alpha1NamespacedCronJob', \@params);
  }
  
  sub PatchBatchV2alpha1NamespacedCronJobStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchBatchV2alpha1NamespacedCronJobStatus', \@params);
  }
  
  sub PatchCertificatesV1beta1CertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke('PatchCertificatesV1beta1CertificateSigningRequest', \@params);
  }
  
  sub PatchCertificatesV1beta1CertificateSigningRequestStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchCertificatesV1beta1CertificateSigningRequestStatus', \@params);
  }
  
  sub PatchCoordinationV1beta1NamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoordinationV1beta1NamespacedLease', \@params);
  }
  
  sub PatchCoreV1Namespace {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1Namespace', \@params);
  }
  
  sub PatchCoreV1NamespaceStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespaceStatus', \@params);
  }
  
  sub PatchCoreV1NamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedConfigMap', \@params);
  }
  
  sub PatchCoreV1NamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedEndpoints', \@params);
  }
  
  sub PatchCoreV1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedEvent', \@params);
  }
  
  sub PatchCoreV1NamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedLimitRange', \@params);
  }
  
  sub PatchCoreV1NamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedPersistentVolumeClaim', \@params);
  }
  
  sub PatchCoreV1NamespacedPersistentVolumeClaimStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedPersistentVolumeClaimStatus', \@params);
  }
  
  sub PatchCoreV1NamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedPod', \@params);
  }
  
  sub PatchCoreV1NamespacedPodStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedPodStatus', \@params);
  }
  
  sub PatchCoreV1NamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedPodTemplate', \@params);
  }
  
  sub PatchCoreV1NamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedReplicationController', \@params);
  }
  
  sub PatchCoreV1NamespacedReplicationControllerScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedReplicationControllerScale', \@params);
  }
  
  sub PatchCoreV1NamespacedReplicationControllerStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedReplicationControllerStatus', \@params);
  }
  
  sub PatchCoreV1NamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedResourceQuota', \@params);
  }
  
  sub PatchCoreV1NamespacedResourceQuotaStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedResourceQuotaStatus', \@params);
  }
  
  sub PatchCoreV1NamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedSecret', \@params);
  }
  
  sub PatchCoreV1NamespacedService {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedService', \@params);
  }
  
  sub PatchCoreV1NamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedServiceAccount', \@params);
  }
  
  sub PatchCoreV1NamespacedServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NamespacedServiceStatus', \@params);
  }
  
  sub PatchCoreV1Node {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1Node', \@params);
  }
  
  sub PatchCoreV1NodeStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1NodeStatus', \@params);
  }
  
  sub PatchCoreV1PersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1PersistentVolume', \@params);
  }
  
  sub PatchCoreV1PersistentVolumeStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchCoreV1PersistentVolumeStatus', \@params);
  }
  
  sub PatchEventsV1beta1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('PatchEventsV1beta1NamespacedEvent', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedDaemonSet', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedDaemonSetStatus', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedDeployment', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedDeploymentScale', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedDeploymentStatus', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedIngress', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedIngressStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedIngressStatus', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedNetworkPolicy', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedReplicaSet', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedReplicaSetScale', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedReplicaSetStatus', \@params);
  }
  
  sub PatchExtensionsV1beta1NamespacedReplicationControllerDummyScale {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1NamespacedReplicationControllerDummyScale', \@params);
  }
  
  sub PatchExtensionsV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('PatchExtensionsV1beta1PodSecurityPolicy', \@params);
  }
  
  sub PatchNetworkingV1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('PatchNetworkingV1NamespacedNetworkPolicy', \@params);
  }
  
  sub PatchPolicyV1beta1NamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke('PatchPolicyV1beta1NamespacedPodDisruptionBudget', \@params);
  }
  
  sub PatchPolicyV1beta1NamespacedPodDisruptionBudgetStatus {
    my ($self, @params) = @_;
    $self->_invoke('PatchPolicyV1beta1NamespacedPodDisruptionBudgetStatus', \@params);
  }
  
  sub PatchPolicyV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('PatchPolicyV1beta1PodSecurityPolicy', \@params);
  }
  
  sub PatchRbacAuthorizationV1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1ClusterRole', \@params);
  }
  
  sub PatchRbacAuthorizationV1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1ClusterRoleBinding', \@params);
  }
  
  sub PatchRbacAuthorizationV1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1NamespacedRole', \@params);
  }
  
  sub PatchRbacAuthorizationV1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1NamespacedRoleBinding', \@params);
  }
  
  sub PatchRbacAuthorizationV1alpha1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1alpha1ClusterRole', \@params);
  }
  
  sub PatchRbacAuthorizationV1alpha1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1alpha1ClusterRoleBinding', \@params);
  }
  
  sub PatchRbacAuthorizationV1alpha1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1alpha1NamespacedRole', \@params);
  }
  
  sub PatchRbacAuthorizationV1alpha1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1alpha1NamespacedRoleBinding', \@params);
  }
  
  sub PatchRbacAuthorizationV1beta1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1beta1ClusterRole', \@params);
  }
  
  sub PatchRbacAuthorizationV1beta1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1beta1ClusterRoleBinding', \@params);
  }
  
  sub PatchRbacAuthorizationV1beta1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1beta1NamespacedRole', \@params);
  }
  
  sub PatchRbacAuthorizationV1beta1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('PatchRbacAuthorizationV1beta1NamespacedRoleBinding', \@params);
  }
  
  sub PatchSchedulingV1alpha1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('PatchSchedulingV1alpha1PriorityClass', \@params);
  }
  
  sub PatchSchedulingV1beta1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('PatchSchedulingV1beta1PriorityClass', \@params);
  }
  
  sub PatchSettingsV1alpha1NamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke('PatchSettingsV1alpha1NamespacedPodPreset', \@params);
  }
  
  sub PatchStorageV1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('PatchStorageV1StorageClass', \@params);
  }
  
  sub PatchStorageV1alpha1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('PatchStorageV1alpha1VolumeAttachment', \@params);
  }
  
  sub PatchStorageV1beta1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('PatchStorageV1beta1StorageClass', \@params);
  }
  
  sub PatchStorageV1beta1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('PatchStorageV1beta1VolumeAttachment', \@params);
  }
  
  sub ReadAdmissionregistrationV1alpha1InitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('ReadAdmissionregistrationV1alpha1InitializerConfiguration', \@params);
  }
  
  sub ReadAdmissionregistrationV1beta1MutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('ReadAdmissionregistrationV1beta1MutatingWebhookConfiguration', \@params);
  }
  
  sub ReadAdmissionregistrationV1beta1ValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('ReadAdmissionregistrationV1beta1ValidatingWebhookConfiguration', \@params);
  }
  
  sub ReadApiextensionsV1beta1CustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke('ReadApiextensionsV1beta1CustomResourceDefinition', \@params);
  }
  
  sub ReadApiextensionsV1beta1CustomResourceDefinitionStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadApiextensionsV1beta1CustomResourceDefinitionStatus', \@params);
  }
  
  sub ReadApiregistrationV1APIService {
    my ($self, @params) = @_;
    $self->_invoke('ReadApiregistrationV1APIService', \@params);
  }
  
  sub ReadApiregistrationV1APIServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadApiregistrationV1APIServiceStatus', \@params);
  }
  
  sub ReadApiregistrationV1beta1APIService {
    my ($self, @params) = @_;
    $self->_invoke('ReadApiregistrationV1beta1APIService', \@params);
  }
  
  sub ReadApiregistrationV1beta1APIServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadApiregistrationV1beta1APIServiceStatus', \@params);
  }
  
  sub ReadAppsV1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedControllerRevision', \@params);
  }
  
  sub ReadAppsV1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedDaemonSet', \@params);
  }
  
  sub ReadAppsV1NamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedDaemonSetStatus', \@params);
  }
  
  sub ReadAppsV1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedDeployment', \@params);
  }
  
  sub ReadAppsV1NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedDeploymentScale', \@params);
  }
  
  sub ReadAppsV1NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedDeploymentStatus', \@params);
  }
  
  sub ReadAppsV1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedReplicaSet', \@params);
  }
  
  sub ReadAppsV1NamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedReplicaSetScale', \@params);
  }
  
  sub ReadAppsV1NamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedReplicaSetStatus', \@params);
  }
  
  sub ReadAppsV1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedStatefulSet', \@params);
  }
  
  sub ReadAppsV1NamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedStatefulSetScale', \@params);
  }
  
  sub ReadAppsV1NamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1NamespacedStatefulSetStatus', \@params);
  }
  
  sub ReadAppsV1beta1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta1NamespacedControllerRevision', \@params);
  }
  
  sub ReadAppsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta1NamespacedDeployment', \@params);
  }
  
  sub ReadAppsV1beta1NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta1NamespacedDeploymentScale', \@params);
  }
  
  sub ReadAppsV1beta1NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta1NamespacedDeploymentStatus', \@params);
  }
  
  sub ReadAppsV1beta1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta1NamespacedStatefulSet', \@params);
  }
  
  sub ReadAppsV1beta1NamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta1NamespacedStatefulSetScale', \@params);
  }
  
  sub ReadAppsV1beta1NamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta1NamespacedStatefulSetStatus', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedControllerRevision', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedDaemonSet', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedDaemonSetStatus', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedDeployment', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedDeploymentScale', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedDeploymentStatus', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedReplicaSet', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedReplicaSetScale', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedReplicaSetStatus', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedStatefulSet', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedStatefulSetScale', \@params);
  }
  
  sub ReadAppsV1beta2NamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAppsV1beta2NamespacedStatefulSetStatus', \@params);
  }
  
  sub ReadAuditregistrationV1alpha1AuditSink {
    my ($self, @params) = @_;
    $self->_invoke('ReadAuditregistrationV1alpha1AuditSink', \@params);
  }
  
  sub ReadAutoscalingV1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('ReadAutoscalingV1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ReadAutoscalingV1NamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAutoscalingV1NamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub ReadAutoscalingV2beta1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('ReadAutoscalingV2beta1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ReadAutoscalingV2beta1NamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAutoscalingV2beta1NamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub ReadAutoscalingV2beta2NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('ReadAutoscalingV2beta2NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ReadAutoscalingV2beta2NamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadAutoscalingV2beta2NamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub ReadBatchV1NamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke('ReadBatchV1NamespacedJob', \@params);
  }
  
  sub ReadBatchV1NamespacedJobStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadBatchV1NamespacedJobStatus', \@params);
  }
  
  sub ReadBatchV1beta1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('ReadBatchV1beta1NamespacedCronJob', \@params);
  }
  
  sub ReadBatchV1beta1NamespacedCronJobStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadBatchV1beta1NamespacedCronJobStatus', \@params);
  }
  
  sub ReadBatchV2alpha1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('ReadBatchV2alpha1NamespacedCronJob', \@params);
  }
  
  sub ReadBatchV2alpha1NamespacedCronJobStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadBatchV2alpha1NamespacedCronJobStatus', \@params);
  }
  
  sub ReadCertificatesV1beta1CertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke('ReadCertificatesV1beta1CertificateSigningRequest', \@params);
  }
  
  sub ReadCertificatesV1beta1CertificateSigningRequestStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadCertificatesV1beta1CertificateSigningRequestStatus', \@params);
  }
  
  sub ReadCoordinationV1beta1NamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoordinationV1beta1NamespacedLease', \@params);
  }
  
  sub ReadCoreV1ComponentStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1ComponentStatus', \@params);
  }
  
  sub ReadCoreV1Namespace {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1Namespace', \@params);
  }
  
  sub ReadCoreV1NamespaceStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespaceStatus', \@params);
  }
  
  sub ReadCoreV1NamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedConfigMap', \@params);
  }
  
  sub ReadCoreV1NamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedEndpoints', \@params);
  }
  
  sub ReadCoreV1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedEvent', \@params);
  }
  
  sub ReadCoreV1NamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedLimitRange', \@params);
  }
  
  sub ReadCoreV1NamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedPersistentVolumeClaim', \@params);
  }
  
  sub ReadCoreV1NamespacedPersistentVolumeClaimStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedPersistentVolumeClaimStatus', \@params);
  }
  
  sub ReadCoreV1NamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedPod', \@params);
  }
  
  sub ReadCoreV1NamespacedPodLog {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedPodLog', \@params);
  }
  
  sub ReadCoreV1NamespacedPodStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedPodStatus', \@params);
  }
  
  sub ReadCoreV1NamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedPodTemplate', \@params);
  }
  
  sub ReadCoreV1NamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedReplicationController', \@params);
  }
  
  sub ReadCoreV1NamespacedReplicationControllerScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedReplicationControllerScale', \@params);
  }
  
  sub ReadCoreV1NamespacedReplicationControllerStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedReplicationControllerStatus', \@params);
  }
  
  sub ReadCoreV1NamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedResourceQuota', \@params);
  }
  
  sub ReadCoreV1NamespacedResourceQuotaStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedResourceQuotaStatus', \@params);
  }
  
  sub ReadCoreV1NamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedSecret', \@params);
  }
  
  sub ReadCoreV1NamespacedService {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedService', \@params);
  }
  
  sub ReadCoreV1NamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedServiceAccount', \@params);
  }
  
  sub ReadCoreV1NamespacedServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NamespacedServiceStatus', \@params);
  }
  
  sub ReadCoreV1Node {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1Node', \@params);
  }
  
  sub ReadCoreV1NodeStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1NodeStatus', \@params);
  }
  
  sub ReadCoreV1PersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1PersistentVolume', \@params);
  }
  
  sub ReadCoreV1PersistentVolumeStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadCoreV1PersistentVolumeStatus', \@params);
  }
  
  sub ReadEventsV1beta1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('ReadEventsV1beta1NamespacedEvent', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedDaemonSet', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedDaemonSetStatus', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedDeployment', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedDeploymentScale', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedDeploymentStatus', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedIngress', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedIngressStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedIngressStatus', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedNetworkPolicy', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedReplicaSet', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedReplicaSetScale', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedReplicaSetStatus', \@params);
  }
  
  sub ReadExtensionsV1beta1NamespacedReplicationControllerDummyScale {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1NamespacedReplicationControllerDummyScale', \@params);
  }
  
  sub ReadExtensionsV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ReadExtensionsV1beta1PodSecurityPolicy', \@params);
  }
  
  sub ReadNetworkingV1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ReadNetworkingV1NamespacedNetworkPolicy', \@params);
  }
  
  sub ReadPolicyV1beta1NamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke('ReadPolicyV1beta1NamespacedPodDisruptionBudget', \@params);
  }
  
  sub ReadPolicyV1beta1NamespacedPodDisruptionBudgetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReadPolicyV1beta1NamespacedPodDisruptionBudgetStatus', \@params);
  }
  
  sub ReadPolicyV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ReadPolicyV1beta1PodSecurityPolicy', \@params);
  }
  
  sub ReadRbacAuthorizationV1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1ClusterRole', \@params);
  }
  
  sub ReadRbacAuthorizationV1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1ClusterRoleBinding', \@params);
  }
  
  sub ReadRbacAuthorizationV1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1NamespacedRole', \@params);
  }
  
  sub ReadRbacAuthorizationV1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1NamespacedRoleBinding', \@params);
  }
  
  sub ReadRbacAuthorizationV1alpha1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1alpha1ClusterRole', \@params);
  }
  
  sub ReadRbacAuthorizationV1alpha1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1alpha1ClusterRoleBinding', \@params);
  }
  
  sub ReadRbacAuthorizationV1alpha1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1alpha1NamespacedRole', \@params);
  }
  
  sub ReadRbacAuthorizationV1alpha1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1alpha1NamespacedRoleBinding', \@params);
  }
  
  sub ReadRbacAuthorizationV1beta1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1beta1ClusterRole', \@params);
  }
  
  sub ReadRbacAuthorizationV1beta1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1beta1ClusterRoleBinding', \@params);
  }
  
  sub ReadRbacAuthorizationV1beta1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1beta1NamespacedRole', \@params);
  }
  
  sub ReadRbacAuthorizationV1beta1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReadRbacAuthorizationV1beta1NamespacedRoleBinding', \@params);
  }
  
  sub ReadSchedulingV1alpha1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('ReadSchedulingV1alpha1PriorityClass', \@params);
  }
  
  sub ReadSchedulingV1beta1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('ReadSchedulingV1beta1PriorityClass', \@params);
  }
  
  sub ReadSettingsV1alpha1NamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke('ReadSettingsV1alpha1NamespacedPodPreset', \@params);
  }
  
  sub ReadStorageV1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('ReadStorageV1StorageClass', \@params);
  }
  
  sub ReadStorageV1alpha1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('ReadStorageV1alpha1VolumeAttachment', \@params);
  }
  
  sub ReadStorageV1beta1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('ReadStorageV1beta1StorageClass', \@params);
  }
  
  sub ReadStorageV1beta1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('ReadStorageV1beta1VolumeAttachment', \@params);
  }
  
  sub ReplaceAdmissionregistrationV1alpha1InitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAdmissionregistrationV1alpha1InitializerConfiguration', \@params);
  }
  
  sub ReplaceAdmissionregistrationV1beta1MutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAdmissionregistrationV1beta1MutatingWebhookConfiguration', \@params);
  }
  
  sub ReplaceAdmissionregistrationV1beta1ValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAdmissionregistrationV1beta1ValidatingWebhookConfiguration', \@params);
  }
  
  sub ReplaceApiextensionsV1beta1CustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceApiextensionsV1beta1CustomResourceDefinition', \@params);
  }
  
  sub ReplaceApiextensionsV1beta1CustomResourceDefinitionStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceApiextensionsV1beta1CustomResourceDefinitionStatus', \@params);
  }
  
  sub ReplaceApiregistrationV1APIService {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceApiregistrationV1APIService', \@params);
  }
  
  sub ReplaceApiregistrationV1APIServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceApiregistrationV1APIServiceStatus', \@params);
  }
  
  sub ReplaceApiregistrationV1beta1APIService {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceApiregistrationV1beta1APIService', \@params);
  }
  
  sub ReplaceApiregistrationV1beta1APIServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceApiregistrationV1beta1APIServiceStatus', \@params);
  }
  
  sub ReplaceAppsV1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedControllerRevision', \@params);
  }
  
  sub ReplaceAppsV1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedDaemonSet', \@params);
  }
  
  sub ReplaceAppsV1NamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedDaemonSetStatus', \@params);
  }
  
  sub ReplaceAppsV1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedDeployment', \@params);
  }
  
  sub ReplaceAppsV1NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedDeploymentScale', \@params);
  }
  
  sub ReplaceAppsV1NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedDeploymentStatus', \@params);
  }
  
  sub ReplaceAppsV1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedReplicaSet', \@params);
  }
  
  sub ReplaceAppsV1NamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedReplicaSetScale', \@params);
  }
  
  sub ReplaceAppsV1NamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedReplicaSetStatus', \@params);
  }
  
  sub ReplaceAppsV1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedStatefulSet', \@params);
  }
  
  sub ReplaceAppsV1NamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedStatefulSetScale', \@params);
  }
  
  sub ReplaceAppsV1NamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1NamespacedStatefulSetStatus', \@params);
  }
  
  sub ReplaceAppsV1beta1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta1NamespacedControllerRevision', \@params);
  }
  
  sub ReplaceAppsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta1NamespacedDeployment', \@params);
  }
  
  sub ReplaceAppsV1beta1NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta1NamespacedDeploymentScale', \@params);
  }
  
  sub ReplaceAppsV1beta1NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta1NamespacedDeploymentStatus', \@params);
  }
  
  sub ReplaceAppsV1beta1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta1NamespacedStatefulSet', \@params);
  }
  
  sub ReplaceAppsV1beta1NamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta1NamespacedStatefulSetScale', \@params);
  }
  
  sub ReplaceAppsV1beta1NamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta1NamespacedStatefulSetStatus', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedControllerRevision', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedDaemonSet', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedDaemonSetStatus', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedDeployment', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedDeploymentScale', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedDeploymentStatus', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedReplicaSet', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedReplicaSetScale', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedReplicaSetStatus', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedStatefulSet', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedStatefulSetScale', \@params);
  }
  
  sub ReplaceAppsV1beta2NamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAppsV1beta2NamespacedStatefulSetStatus', \@params);
  }
  
  sub ReplaceAuditregistrationV1alpha1AuditSink {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAuditregistrationV1alpha1AuditSink', \@params);
  }
  
  sub ReplaceAutoscalingV1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAutoscalingV1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ReplaceAutoscalingV1NamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAutoscalingV1NamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub ReplaceAutoscalingV2beta1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAutoscalingV2beta1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ReplaceAutoscalingV2beta1NamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAutoscalingV2beta1NamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub ReplaceAutoscalingV2beta2NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAutoscalingV2beta2NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ReplaceAutoscalingV2beta2NamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceAutoscalingV2beta2NamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub ReplaceBatchV1NamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceBatchV1NamespacedJob', \@params);
  }
  
  sub ReplaceBatchV1NamespacedJobStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceBatchV1NamespacedJobStatus', \@params);
  }
  
  sub ReplaceBatchV1beta1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceBatchV1beta1NamespacedCronJob', \@params);
  }
  
  sub ReplaceBatchV1beta1NamespacedCronJobStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceBatchV1beta1NamespacedCronJobStatus', \@params);
  }
  
  sub ReplaceBatchV2alpha1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceBatchV2alpha1NamespacedCronJob', \@params);
  }
  
  sub ReplaceBatchV2alpha1NamespacedCronJobStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceBatchV2alpha1NamespacedCronJobStatus', \@params);
  }
  
  sub ReplaceCertificatesV1beta1CertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCertificatesV1beta1CertificateSigningRequest', \@params);
  }
  
  sub ReplaceCertificatesV1beta1CertificateSigningRequestApproval {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCertificatesV1beta1CertificateSigningRequestApproval', \@params);
  }
  
  sub ReplaceCertificatesV1beta1CertificateSigningRequestStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCertificatesV1beta1CertificateSigningRequestStatus', \@params);
  }
  
  sub ReplaceCoordinationV1beta1NamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoordinationV1beta1NamespacedLease', \@params);
  }
  
  sub ReplaceCoreV1Namespace {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1Namespace', \@params);
  }
  
  sub ReplaceCoreV1NamespaceFinalize {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespaceFinalize', \@params);
  }
  
  sub ReplaceCoreV1NamespaceStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespaceStatus', \@params);
  }
  
  sub ReplaceCoreV1NamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedConfigMap', \@params);
  }
  
  sub ReplaceCoreV1NamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedEndpoints', \@params);
  }
  
  sub ReplaceCoreV1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedEvent', \@params);
  }
  
  sub ReplaceCoreV1NamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedLimitRange', \@params);
  }
  
  sub ReplaceCoreV1NamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedPersistentVolumeClaim', \@params);
  }
  
  sub ReplaceCoreV1NamespacedPersistentVolumeClaimStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedPersistentVolumeClaimStatus', \@params);
  }
  
  sub ReplaceCoreV1NamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedPod', \@params);
  }
  
  sub ReplaceCoreV1NamespacedPodStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedPodStatus', \@params);
  }
  
  sub ReplaceCoreV1NamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedPodTemplate', \@params);
  }
  
  sub ReplaceCoreV1NamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedReplicationController', \@params);
  }
  
  sub ReplaceCoreV1NamespacedReplicationControllerScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedReplicationControllerScale', \@params);
  }
  
  sub ReplaceCoreV1NamespacedReplicationControllerStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedReplicationControllerStatus', \@params);
  }
  
  sub ReplaceCoreV1NamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedResourceQuota', \@params);
  }
  
  sub ReplaceCoreV1NamespacedResourceQuotaStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedResourceQuotaStatus', \@params);
  }
  
  sub ReplaceCoreV1NamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedSecret', \@params);
  }
  
  sub ReplaceCoreV1NamespacedService {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedService', \@params);
  }
  
  sub ReplaceCoreV1NamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedServiceAccount', \@params);
  }
  
  sub ReplaceCoreV1NamespacedServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NamespacedServiceStatus', \@params);
  }
  
  sub ReplaceCoreV1Node {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1Node', \@params);
  }
  
  sub ReplaceCoreV1NodeStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1NodeStatus', \@params);
  }
  
  sub ReplaceCoreV1PersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1PersistentVolume', \@params);
  }
  
  sub ReplaceCoreV1PersistentVolumeStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceCoreV1PersistentVolumeStatus', \@params);
  }
  
  sub ReplaceEventsV1beta1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceEventsV1beta1NamespacedEvent', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedDaemonSet', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedDaemonSetStatus', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedDeployment', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedDeploymentScale', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedDeploymentStatus', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedIngress', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedIngressStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedIngressStatus', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedNetworkPolicy', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedReplicaSet', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedReplicaSetScale', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedReplicaSetStatus', \@params);
  }
  
  sub ReplaceExtensionsV1beta1NamespacedReplicationControllerDummyScale {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1NamespacedReplicationControllerDummyScale', \@params);
  }
  
  sub ReplaceExtensionsV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceExtensionsV1beta1PodSecurityPolicy', \@params);
  }
  
  sub ReplaceNetworkingV1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceNetworkingV1NamespacedNetworkPolicy', \@params);
  }
  
  sub ReplacePolicyV1beta1NamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke('ReplacePolicyV1beta1NamespacedPodDisruptionBudget', \@params);
  }
  
  sub ReplacePolicyV1beta1NamespacedPodDisruptionBudgetStatus {
    my ($self, @params) = @_;
    $self->_invoke('ReplacePolicyV1beta1NamespacedPodDisruptionBudgetStatus', \@params);
  }
  
  sub ReplacePolicyV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('ReplacePolicyV1beta1PodSecurityPolicy', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1ClusterRole', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1ClusterRoleBinding', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1NamespacedRole', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1NamespacedRoleBinding', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1alpha1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1alpha1ClusterRole', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1alpha1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1alpha1ClusterRoleBinding', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1alpha1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1alpha1NamespacedRole', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1alpha1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1alpha1NamespacedRoleBinding', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1beta1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1beta1ClusterRole', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1beta1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1beta1ClusterRoleBinding', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1beta1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1beta1NamespacedRole', \@params);
  }
  
  sub ReplaceRbacAuthorizationV1beta1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceRbacAuthorizationV1beta1NamespacedRoleBinding', \@params);
  }
  
  sub ReplaceSchedulingV1alpha1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceSchedulingV1alpha1PriorityClass', \@params);
  }
  
  sub ReplaceSchedulingV1beta1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceSchedulingV1beta1PriorityClass', \@params);
  }
  
  sub ReplaceSettingsV1alpha1NamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceSettingsV1alpha1NamespacedPodPreset', \@params);
  }
  
  sub ReplaceStorageV1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceStorageV1StorageClass', \@params);
  }
  
  sub ReplaceStorageV1alpha1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceStorageV1alpha1VolumeAttachment', \@params);
  }
  
  sub ReplaceStorageV1beta1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceStorageV1beta1StorageClass', \@params);
  }
  
  sub ReplaceStorageV1beta1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('ReplaceStorageV1beta1VolumeAttachment', \@params);
  }
  
  sub WatchAdmissionregistrationV1alpha1InitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('WatchAdmissionregistrationV1alpha1InitializerConfiguration', \@params);
  }
  
  sub WatchAdmissionregistrationV1alpha1InitializerConfigurationList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAdmissionregistrationV1alpha1InitializerConfigurationList', \@params);
  }
  
  sub WatchAdmissionregistrationV1beta1MutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('WatchAdmissionregistrationV1beta1MutatingWebhookConfiguration', \@params);
  }
  
  sub WatchAdmissionregistrationV1beta1MutatingWebhookConfigurationList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAdmissionregistrationV1beta1MutatingWebhookConfigurationList', \@params);
  }
  
  sub WatchAdmissionregistrationV1beta1ValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke('WatchAdmissionregistrationV1beta1ValidatingWebhookConfiguration', \@params);
  }
  
  sub WatchAdmissionregistrationV1beta1ValidatingWebhookConfigurationList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAdmissionregistrationV1beta1ValidatingWebhookConfigurationList', \@params);
  }
  
  sub WatchApiextensionsV1beta1CustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke('WatchApiextensionsV1beta1CustomResourceDefinition', \@params);
  }
  
  sub WatchApiextensionsV1beta1CustomResourceDefinitionList {
    my ($self, @params) = @_;
    $self->_invoke('WatchApiextensionsV1beta1CustomResourceDefinitionList', \@params);
  }
  
  sub WatchApiregistrationV1APIService {
    my ($self, @params) = @_;
    $self->_invoke('WatchApiregistrationV1APIService', \@params);
  }
  
  sub WatchApiregistrationV1APIServiceList {
    my ($self, @params) = @_;
    $self->_invoke('WatchApiregistrationV1APIServiceList', \@params);
  }
  
  sub WatchApiregistrationV1beta1APIService {
    my ($self, @params) = @_;
    $self->_invoke('WatchApiregistrationV1beta1APIService', \@params);
  }
  
  sub WatchApiregistrationV1beta1APIServiceList {
    my ($self, @params) = @_;
    $self->_invoke('WatchApiregistrationV1beta1APIServiceList', \@params);
  }
  
  sub WatchAppsV1ControllerRevisionListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1ControllerRevisionListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1DaemonSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1DaemonSetListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1DeploymentListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1DeploymentListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1NamespacedControllerRevision', \@params);
  }
  
  sub WatchAppsV1NamespacedControllerRevisionList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1NamespacedControllerRevisionList', \@params);
  }
  
  sub WatchAppsV1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1NamespacedDaemonSet', \@params);
  }
  
  sub WatchAppsV1NamespacedDaemonSetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1NamespacedDaemonSetList', \@params);
  }
  
  sub WatchAppsV1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1NamespacedDeployment', \@params);
  }
  
  sub WatchAppsV1NamespacedDeploymentList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1NamespacedDeploymentList', \@params);
  }
  
  sub WatchAppsV1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1NamespacedReplicaSet', \@params);
  }
  
  sub WatchAppsV1NamespacedReplicaSetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1NamespacedReplicaSetList', \@params);
  }
  
  sub WatchAppsV1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1NamespacedStatefulSet', \@params);
  }
  
  sub WatchAppsV1NamespacedStatefulSetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1NamespacedStatefulSetList', \@params);
  }
  
  sub WatchAppsV1ReplicaSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1ReplicaSetListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1StatefulSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1StatefulSetListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1beta1ControllerRevisionListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta1ControllerRevisionListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1beta1DeploymentListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta1DeploymentListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1beta1NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta1NamespacedControllerRevision', \@params);
  }
  
  sub WatchAppsV1beta1NamespacedControllerRevisionList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta1NamespacedControllerRevisionList', \@params);
  }
  
  sub WatchAppsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta1NamespacedDeployment', \@params);
  }
  
  sub WatchAppsV1beta1NamespacedDeploymentList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta1NamespacedDeploymentList', \@params);
  }
  
  sub WatchAppsV1beta1NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta1NamespacedStatefulSet', \@params);
  }
  
  sub WatchAppsV1beta1NamespacedStatefulSetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta1NamespacedStatefulSetList', \@params);
  }
  
  sub WatchAppsV1beta1StatefulSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta1StatefulSetListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1beta2ControllerRevisionListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2ControllerRevisionListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1beta2DaemonSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2DaemonSetListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1beta2DeploymentListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2DeploymentListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1beta2NamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2NamespacedControllerRevision', \@params);
  }
  
  sub WatchAppsV1beta2NamespacedControllerRevisionList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2NamespacedControllerRevisionList', \@params);
  }
  
  sub WatchAppsV1beta2NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2NamespacedDaemonSet', \@params);
  }
  
  sub WatchAppsV1beta2NamespacedDaemonSetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2NamespacedDaemonSetList', \@params);
  }
  
  sub WatchAppsV1beta2NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2NamespacedDeployment', \@params);
  }
  
  sub WatchAppsV1beta2NamespacedDeploymentList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2NamespacedDeploymentList', \@params);
  }
  
  sub WatchAppsV1beta2NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2NamespacedReplicaSet', \@params);
  }
  
  sub WatchAppsV1beta2NamespacedReplicaSetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2NamespacedReplicaSetList', \@params);
  }
  
  sub WatchAppsV1beta2NamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2NamespacedStatefulSet', \@params);
  }
  
  sub WatchAppsV1beta2NamespacedStatefulSetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2NamespacedStatefulSetList', \@params);
  }
  
  sub WatchAppsV1beta2ReplicaSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2ReplicaSetListForAllNamespaces', \@params);
  }
  
  sub WatchAppsV1beta2StatefulSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAppsV1beta2StatefulSetListForAllNamespaces', \@params);
  }
  
  sub WatchAuditregistrationV1alpha1AuditSink {
    my ($self, @params) = @_;
    $self->_invoke('WatchAuditregistrationV1alpha1AuditSink', \@params);
  }
  
  sub WatchAuditregistrationV1alpha1AuditSinkList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAuditregistrationV1alpha1AuditSinkList', \@params);
  }
  
  sub WatchAutoscalingV1HorizontalPodAutoscalerListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAutoscalingV1HorizontalPodAutoscalerListForAllNamespaces', \@params);
  }
  
  sub WatchAutoscalingV1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('WatchAutoscalingV1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub WatchAutoscalingV1NamespacedHorizontalPodAutoscalerList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAutoscalingV1NamespacedHorizontalPodAutoscalerList', \@params);
  }
  
  sub WatchAutoscalingV2beta1HorizontalPodAutoscalerListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAutoscalingV2beta1HorizontalPodAutoscalerListForAllNamespaces', \@params);
  }
  
  sub WatchAutoscalingV2beta1NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('WatchAutoscalingV2beta1NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub WatchAutoscalingV2beta1NamespacedHorizontalPodAutoscalerList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAutoscalingV2beta1NamespacedHorizontalPodAutoscalerList', \@params);
  }
  
  sub WatchAutoscalingV2beta2HorizontalPodAutoscalerListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchAutoscalingV2beta2HorizontalPodAutoscalerListForAllNamespaces', \@params);
  }
  
  sub WatchAutoscalingV2beta2NamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke('WatchAutoscalingV2beta2NamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub WatchAutoscalingV2beta2NamespacedHorizontalPodAutoscalerList {
    my ($self, @params) = @_;
    $self->_invoke('WatchAutoscalingV2beta2NamespacedHorizontalPodAutoscalerList', \@params);
  }
  
  sub WatchBatchV1JobListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchBatchV1JobListForAllNamespaces', \@params);
  }
  
  sub WatchBatchV1NamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke('WatchBatchV1NamespacedJob', \@params);
  }
  
  sub WatchBatchV1NamespacedJobList {
    my ($self, @params) = @_;
    $self->_invoke('WatchBatchV1NamespacedJobList', \@params);
  }
  
  sub WatchBatchV1beta1CronJobListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchBatchV1beta1CronJobListForAllNamespaces', \@params);
  }
  
  sub WatchBatchV1beta1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('WatchBatchV1beta1NamespacedCronJob', \@params);
  }
  
  sub WatchBatchV1beta1NamespacedCronJobList {
    my ($self, @params) = @_;
    $self->_invoke('WatchBatchV1beta1NamespacedCronJobList', \@params);
  }
  
  sub WatchBatchV2alpha1CronJobListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchBatchV2alpha1CronJobListForAllNamespaces', \@params);
  }
  
  sub WatchBatchV2alpha1NamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke('WatchBatchV2alpha1NamespacedCronJob', \@params);
  }
  
  sub WatchBatchV2alpha1NamespacedCronJobList {
    my ($self, @params) = @_;
    $self->_invoke('WatchBatchV2alpha1NamespacedCronJobList', \@params);
  }
  
  sub WatchCertificatesV1beta1CertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke('WatchCertificatesV1beta1CertificateSigningRequest', \@params);
  }
  
  sub WatchCertificatesV1beta1CertificateSigningRequestList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCertificatesV1beta1CertificateSigningRequestList', \@params);
  }
  
  sub WatchCoordinationV1beta1LeaseListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoordinationV1beta1LeaseListForAllNamespaces', \@params);
  }
  
  sub WatchCoordinationV1beta1NamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoordinationV1beta1NamespacedLease', \@params);
  }
  
  sub WatchCoordinationV1beta1NamespacedLeaseList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoordinationV1beta1NamespacedLeaseList', \@params);
  }
  
  sub WatchCoreV1ConfigMapListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1ConfigMapListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1EndpointsListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1EndpointsListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1EventListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1EventListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1LimitRangeListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1LimitRangeListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1Namespace {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1Namespace', \@params);
  }
  
  sub WatchCoreV1NamespaceList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespaceList', \@params);
  }
  
  sub WatchCoreV1NamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedConfigMap', \@params);
  }
  
  sub WatchCoreV1NamespacedConfigMapList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedConfigMapList', \@params);
  }
  
  sub WatchCoreV1NamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedEndpoints', \@params);
  }
  
  sub WatchCoreV1NamespacedEndpointsList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedEndpointsList', \@params);
  }
  
  sub WatchCoreV1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedEvent', \@params);
  }
  
  sub WatchCoreV1NamespacedEventList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedEventList', \@params);
  }
  
  sub WatchCoreV1NamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedLimitRange', \@params);
  }
  
  sub WatchCoreV1NamespacedLimitRangeList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedLimitRangeList', \@params);
  }
  
  sub WatchCoreV1NamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedPersistentVolumeClaim', \@params);
  }
  
  sub WatchCoreV1NamespacedPersistentVolumeClaimList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedPersistentVolumeClaimList', \@params);
  }
  
  sub WatchCoreV1NamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedPod', \@params);
  }
  
  sub WatchCoreV1NamespacedPodList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedPodList', \@params);
  }
  
  sub WatchCoreV1NamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedPodTemplate', \@params);
  }
  
  sub WatchCoreV1NamespacedPodTemplateList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedPodTemplateList', \@params);
  }
  
  sub WatchCoreV1NamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedReplicationController', \@params);
  }
  
  sub WatchCoreV1NamespacedReplicationControllerList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedReplicationControllerList', \@params);
  }
  
  sub WatchCoreV1NamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedResourceQuota', \@params);
  }
  
  sub WatchCoreV1NamespacedResourceQuotaList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedResourceQuotaList', \@params);
  }
  
  sub WatchCoreV1NamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedSecret', \@params);
  }
  
  sub WatchCoreV1NamespacedSecretList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedSecretList', \@params);
  }
  
  sub WatchCoreV1NamespacedService {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedService', \@params);
  }
  
  sub WatchCoreV1NamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedServiceAccount', \@params);
  }
  
  sub WatchCoreV1NamespacedServiceAccountList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedServiceAccountList', \@params);
  }
  
  sub WatchCoreV1NamespacedServiceList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NamespacedServiceList', \@params);
  }
  
  sub WatchCoreV1Node {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1Node', \@params);
  }
  
  sub WatchCoreV1NodeList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1NodeList', \@params);
  }
  
  sub WatchCoreV1PersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1PersistentVolume', \@params);
  }
  
  sub WatchCoreV1PersistentVolumeClaimListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1PersistentVolumeClaimListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1PersistentVolumeList {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1PersistentVolumeList', \@params);
  }
  
  sub WatchCoreV1PodListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1PodListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1PodTemplateListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1PodTemplateListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1ReplicationControllerListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1ReplicationControllerListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1ResourceQuotaListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1ResourceQuotaListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1SecretListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1SecretListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1ServiceAccountListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1ServiceAccountListForAllNamespaces', \@params);
  }
  
  sub WatchCoreV1ServiceListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchCoreV1ServiceListForAllNamespaces', \@params);
  }
  
  sub WatchEventsV1beta1EventListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchEventsV1beta1EventListForAllNamespaces', \@params);
  }
  
  sub WatchEventsV1beta1NamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke('WatchEventsV1beta1NamespacedEvent', \@params);
  }
  
  sub WatchEventsV1beta1NamespacedEventList {
    my ($self, @params) = @_;
    $self->_invoke('WatchEventsV1beta1NamespacedEventList', \@params);
  }
  
  sub WatchExtensionsV1beta1DaemonSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1DaemonSetListForAllNamespaces', \@params);
  }
  
  sub WatchExtensionsV1beta1DeploymentListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1DeploymentListForAllNamespaces', \@params);
  }
  
  sub WatchExtensionsV1beta1IngressListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1IngressListForAllNamespaces', \@params);
  }
  
  sub WatchExtensionsV1beta1NamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NamespacedDaemonSet', \@params);
  }
  
  sub WatchExtensionsV1beta1NamespacedDaemonSetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NamespacedDaemonSetList', \@params);
  }
  
  sub WatchExtensionsV1beta1NamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NamespacedDeployment', \@params);
  }
  
  sub WatchExtensionsV1beta1NamespacedDeploymentList {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NamespacedDeploymentList', \@params);
  }
  
  sub WatchExtensionsV1beta1NamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NamespacedIngress', \@params);
  }
  
  sub WatchExtensionsV1beta1NamespacedIngressList {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NamespacedIngressList', \@params);
  }
  
  sub WatchExtensionsV1beta1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NamespacedNetworkPolicy', \@params);
  }
  
  sub WatchExtensionsV1beta1NamespacedNetworkPolicyList {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NamespacedNetworkPolicyList', \@params);
  }
  
  sub WatchExtensionsV1beta1NamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NamespacedReplicaSet', \@params);
  }
  
  sub WatchExtensionsV1beta1NamespacedReplicaSetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NamespacedReplicaSetList', \@params);
  }
  
  sub WatchExtensionsV1beta1NetworkPolicyListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1NetworkPolicyListForAllNamespaces', \@params);
  }
  
  sub WatchExtensionsV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1PodSecurityPolicy', \@params);
  }
  
  sub WatchExtensionsV1beta1PodSecurityPolicyList {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1PodSecurityPolicyList', \@params);
  }
  
  sub WatchExtensionsV1beta1ReplicaSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchExtensionsV1beta1ReplicaSetListForAllNamespaces', \@params);
  }
  
  sub WatchNetworkingV1NamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke('WatchNetworkingV1NamespacedNetworkPolicy', \@params);
  }
  
  sub WatchNetworkingV1NamespacedNetworkPolicyList {
    my ($self, @params) = @_;
    $self->_invoke('WatchNetworkingV1NamespacedNetworkPolicyList', \@params);
  }
  
  sub WatchNetworkingV1NetworkPolicyListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchNetworkingV1NetworkPolicyListForAllNamespaces', \@params);
  }
  
  sub WatchPolicyV1beta1NamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke('WatchPolicyV1beta1NamespacedPodDisruptionBudget', \@params);
  }
  
  sub WatchPolicyV1beta1NamespacedPodDisruptionBudgetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchPolicyV1beta1NamespacedPodDisruptionBudgetList', \@params);
  }
  
  sub WatchPolicyV1beta1PodDisruptionBudgetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchPolicyV1beta1PodDisruptionBudgetListForAllNamespaces', \@params);
  }
  
  sub WatchPolicyV1beta1PodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke('WatchPolicyV1beta1PodSecurityPolicy', \@params);
  }
  
  sub WatchPolicyV1beta1PodSecurityPolicyList {
    my ($self, @params) = @_;
    $self->_invoke('WatchPolicyV1beta1PodSecurityPolicyList', \@params);
  }
  
  sub WatchRbacAuthorizationV1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1ClusterRole', \@params);
  }
  
  sub WatchRbacAuthorizationV1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1ClusterRoleBinding', \@params);
  }
  
  sub WatchRbacAuthorizationV1ClusterRoleBindingList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1ClusterRoleBindingList', \@params);
  }
  
  sub WatchRbacAuthorizationV1ClusterRoleList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1ClusterRoleList', \@params);
  }
  
  sub WatchRbacAuthorizationV1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1NamespacedRole', \@params);
  }
  
  sub WatchRbacAuthorizationV1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1NamespacedRoleBinding', \@params);
  }
  
  sub WatchRbacAuthorizationV1NamespacedRoleBindingList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1NamespacedRoleBindingList', \@params);
  }
  
  sub WatchRbacAuthorizationV1NamespacedRoleList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1NamespacedRoleList', \@params);
  }
  
  sub WatchRbacAuthorizationV1RoleBindingListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1RoleBindingListForAllNamespaces', \@params);
  }
  
  sub WatchRbacAuthorizationV1RoleListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1RoleListForAllNamespaces', \@params);
  }
  
  sub WatchRbacAuthorizationV1alpha1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1alpha1ClusterRole', \@params);
  }
  
  sub WatchRbacAuthorizationV1alpha1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1alpha1ClusterRoleBinding', \@params);
  }
  
  sub WatchRbacAuthorizationV1alpha1ClusterRoleBindingList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1alpha1ClusterRoleBindingList', \@params);
  }
  
  sub WatchRbacAuthorizationV1alpha1ClusterRoleList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1alpha1ClusterRoleList', \@params);
  }
  
  sub WatchRbacAuthorizationV1alpha1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1alpha1NamespacedRole', \@params);
  }
  
  sub WatchRbacAuthorizationV1alpha1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1alpha1NamespacedRoleBinding', \@params);
  }
  
  sub WatchRbacAuthorizationV1alpha1NamespacedRoleBindingList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1alpha1NamespacedRoleBindingList', \@params);
  }
  
  sub WatchRbacAuthorizationV1alpha1NamespacedRoleList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1alpha1NamespacedRoleList', \@params);
  }
  
  sub WatchRbacAuthorizationV1alpha1RoleBindingListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1alpha1RoleBindingListForAllNamespaces', \@params);
  }
  
  sub WatchRbacAuthorizationV1alpha1RoleListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1alpha1RoleListForAllNamespaces', \@params);
  }
  
  sub WatchRbacAuthorizationV1beta1ClusterRole {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1beta1ClusterRole', \@params);
  }
  
  sub WatchRbacAuthorizationV1beta1ClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1beta1ClusterRoleBinding', \@params);
  }
  
  sub WatchRbacAuthorizationV1beta1ClusterRoleBindingList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1beta1ClusterRoleBindingList', \@params);
  }
  
  sub WatchRbacAuthorizationV1beta1ClusterRoleList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1beta1ClusterRoleList', \@params);
  }
  
  sub WatchRbacAuthorizationV1beta1NamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1beta1NamespacedRole', \@params);
  }
  
  sub WatchRbacAuthorizationV1beta1NamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1beta1NamespacedRoleBinding', \@params);
  }
  
  sub WatchRbacAuthorizationV1beta1NamespacedRoleBindingList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1beta1NamespacedRoleBindingList', \@params);
  }
  
  sub WatchRbacAuthorizationV1beta1NamespacedRoleList {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1beta1NamespacedRoleList', \@params);
  }
  
  sub WatchRbacAuthorizationV1beta1RoleBindingListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1beta1RoleBindingListForAllNamespaces', \@params);
  }
  
  sub WatchRbacAuthorizationV1beta1RoleListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchRbacAuthorizationV1beta1RoleListForAllNamespaces', \@params);
  }
  
  sub WatchSchedulingV1alpha1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('WatchSchedulingV1alpha1PriorityClass', \@params);
  }
  
  sub WatchSchedulingV1alpha1PriorityClassList {
    my ($self, @params) = @_;
    $self->_invoke('WatchSchedulingV1alpha1PriorityClassList', \@params);
  }
  
  sub WatchSchedulingV1beta1PriorityClass {
    my ($self, @params) = @_;
    $self->_invoke('WatchSchedulingV1beta1PriorityClass', \@params);
  }
  
  sub WatchSchedulingV1beta1PriorityClassList {
    my ($self, @params) = @_;
    $self->_invoke('WatchSchedulingV1beta1PriorityClassList', \@params);
  }
  
  sub WatchSettingsV1alpha1NamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke('WatchSettingsV1alpha1NamespacedPodPreset', \@params);
  }
  
  sub WatchSettingsV1alpha1NamespacedPodPresetList {
    my ($self, @params) = @_;
    $self->_invoke('WatchSettingsV1alpha1NamespacedPodPresetList', \@params);
  }
  
  sub WatchSettingsV1alpha1PodPresetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke('WatchSettingsV1alpha1PodPresetListForAllNamespaces', \@params);
  }
  
  sub WatchStorageV1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('WatchStorageV1StorageClass', \@params);
  }
  
  sub WatchStorageV1StorageClassList {
    my ($self, @params) = @_;
    $self->_invoke('WatchStorageV1StorageClassList', \@params);
  }
  
  sub WatchStorageV1alpha1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('WatchStorageV1alpha1VolumeAttachment', \@params);
  }
  
  sub WatchStorageV1alpha1VolumeAttachmentList {
    my ($self, @params) = @_;
    $self->_invoke('WatchStorageV1alpha1VolumeAttachmentList', \@params);
  }
  
  sub WatchStorageV1beta1StorageClass {
    my ($self, @params) = @_;
    $self->_invoke('WatchStorageV1beta1StorageClass', \@params);
  }
  
  sub WatchStorageV1beta1StorageClassList {
    my ($self, @params) = @_;
    $self->_invoke('WatchStorageV1beta1StorageClassList', \@params);
  }
  
  sub WatchStorageV1beta1VolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke('WatchStorageV1beta1VolumeAttachment', \@params);
  }
  
  sub WatchStorageV1beta1VolumeAttachmentList {
    my ($self, @params) = @_;
    $self->_invoke('WatchStorageV1beta1VolumeAttachmentList', \@params);
  }
  

1;
