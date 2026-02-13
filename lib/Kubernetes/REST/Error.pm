package Kubernetes::REST::Error;
our $VERSION = '1.001';
# ABSTRACT: DEPRECATED - v0 error classes
  use Moo;
  use Types::Standard qw/Str/;
  extends 'Throwable::Error';

  has type => (is => 'ro', isa => Str, required => 1);

=attr type

Error type string.

=cut

  has detail => (is => 'ro');

=attr detail

Optional detailed error message.

=cut

  sub header {
    my $self = shift;
    return sprintf "Exception with type: %s: %s", $self->type, $self->message;
  }

=method header

Returns the error header string.

=cut

  sub as_string {
    my $self = shift;
    if (defined $self->detail) {
      return sprintf "%s\nDetail: %s", $self->header, $self->detail;
    } else {
      return $self->header;
    }
  }

=method as_string

Returns the full error message as a string, including detail if available.

=cut

package Kubernetes::REST::RemoteError;
our $VERSION = '1.001';
# ABSTRACT: DEPRECATED - v0 remote error class
  use Moo;
  use Types::Standard qw/Int/;
  extends 'Kubernetes::REST::Error';

  has '+type' => (default => sub { 'Remote' });
  has status => (is => 'ro', isa => Int, required => 1);

=attr status

HTTP status code.

=cut

  around header => sub {
    my ($orig, $self) = @_;
    my $orig_message = $self->$orig;
    sprintf "%s with HTTP status %d", $orig_message, $self->status;
  };

=head1 DESCRIPTION

B<These error classes are DEPRECATED>. The new v1 API uses C<croak> for errors instead of throwing structured exceptions.

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=cut

1;
