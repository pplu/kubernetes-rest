package Kubernetes::REST::Result2Hash;
  use Moo;
  use JSON::MaybeXS;
  use Kubernetes::REST::Error;

  has parser => (is => 'ro', default => sub { JSON::MaybeXS->new });

  sub result2return {
    my ($self, $response) = @_;

    if ($response->status >= 400) {
      return $self->process_error($response);
    } else {
      return 1 if (not defined $response->content);
      return $self->process_response($response);
    } 
  }

  sub process_response {
    my ($self, $response) = @_;
    
    my $struct = eval {
      $self->parser->decode($response->content);
    };
    Kubernetes::REST::Error->throw(
      type => 'UnparseableResponse',
      message => 'Can\'t parse response ' . $response->content . ' with error ' . $@
    ) if ($@);

    return $struct;
  }

  sub process_error {
    my ($self, $response) = @_;

    my $struct = eval {
      $self->parser->decode($response->content);
    };

    Kubernetes::REST::Error->throw(
      type => 'UnparseableResponse',
      message => 'Can\'t parse JSON content',
      detail => $response->content,
    ) if ($@);

    # Throw a Kubernetes::REST::RemoteError exception from
    # the info in $struct
  }

1;
