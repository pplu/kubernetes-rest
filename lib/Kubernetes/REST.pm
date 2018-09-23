package Kubernetes::REST;
  use Moo;
  use Types::Standard qw/HasMethods/;

  our $VERSION = '0.01';

  has param_converter => (is => 'ro', isa => HasMethods['params2request'], default => sub {
    require Kubernetes::REST::ListToRequest;
    Kubernetes::REST::ListToRequest->new;  
  });
  has io => (is => 'ro', isa => HasMethods['call'], default => sub {
    require Kubernetes::REST::HTTPTinyIO;  
    Kubernetes::REST::HTTPTinyIO->new;
  });
  has result_parser => (is => 'ro', isa => HasMethods['result2return'], default => sub {
    require Kubernetes::REST::Result2Hash;
    Kubernetes::REST::Result2Hash->new
  });

  sub _invoke {
    my ($self, $method, $params) = @_;
    my $req = $self->param_converter->params2request($method, $params);
    my $result = $self->io->call($req);
    return $self->result_parser->result2return($result);
  }

  sub GetCoreAPIVersions {
    my ($self, @params) = @_;
    $self->_invoke('GetCoreAPIVersions', [ @params ]);
  }

1;
