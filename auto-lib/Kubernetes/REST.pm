package Kubernetes::REST;
  use Moo;
  use Types::Standard qw/HasMethods Str InstanceOf/;
  use Kubernetes::REST::CallContext;
  use Kubernetes::REST::Server;
  use Kubernetes::REST::AuthToken;
  use Module::Runtime qw/require_module/;

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
  has credentials => (
    is => 'ro',
    required => 1,
    coerce => sub {
      return Kubernetes::REST::AuthToken->new($_[0]) if (ref($_[0]) eq 'HASH');
      return $_[0];
    }
  );

  has api_version => (is => 'ro', isa => Str, default => sub { 'v1' });

  sub _get_group {
    my ($self, $g) = @_;
    my $group = "Kubernetes::REST::$g";
    require_module $group;
    return $group->new(
      param_converter => $self->param_converter,
      io => $self->io,
      result_parser => $self->result_parser,
      server => $self->server,
      credentials => $self->credentials,
      api_version => $self->api_version,
    );
  }

  
  sub Admissionregistration { shift->_get_group('Admissionregistration') }
  
  sub Apiextensions { shift->_get_group('Apiextensions') }
  
  sub Apiregistration { shift->_get_group('Apiregistration') }
  
  sub Apis { shift->_get_group('Apis') }
  
  sub Apps { shift->_get_group('Apps') }
  
  sub Auditregistration { shift->_get_group('Auditregistration') }
  
  sub Authentication { shift->_get_group('Authentication') }
  
  sub Authorization { shift->_get_group('Authorization') }
  
  sub Autoscaling { shift->_get_group('Autoscaling') }
  
  sub Batch { shift->_get_group('Batch') }
  
  sub Certificates { shift->_get_group('Certificates') }
  
  sub Coordination { shift->_get_group('Coordination') }
  
  sub Core { shift->_get_group('Core') }
  
  sub Events { shift->_get_group('Events') }
  
  sub Extensions { shift->_get_group('Extensions') }
  
  sub Logs { shift->_get_group('Logs') }
  
  sub Networking { shift->_get_group('Networking') }
  
  sub Policy { shift->_get_group('Policy') }
  
  sub RbacAuthorization { shift->_get_group('RbacAuthorization') }
  
  sub Scheduling { shift->_get_group('Scheduling') }
  
  sub Settings { shift->_get_group('Settings') }
  
  sub Storage { shift->_get_group('Storage') }
  
  sub Version { shift->_get_group('Version') }
  

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

  sub invoke_raw {
    my ($self, $req) = @_;
    if (not $req->isa('Kubernetes::REST::HTTPRequest')) {
      die "invoke_raw expects a Kubernetes::REST::HTTPRequest object";
    }

    my $call = Kubernetes::REST::CallContext->new(
      method => "",
      params => [],
      server => $self->server,
      credentials => $self->credentials,
    );
    return $self->io->call($call, $req);
  }

  sub GetAllAPIVersions {
    my ($self, @params) = @_;
    $self->_invoke('GetAllAPIVersions', \@params);
  }

1;
