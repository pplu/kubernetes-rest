package Kubernetes::REST::Error;
our $VERSION = '1.107';
# ABSTRACT: Compatibility helper for deprecated v0 error handling
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

=head1 DESCRIPTION

These error classes belong to the deprecated v0 API - the v1 API croaks instead of throwing structured exceptions. They stay around so code that still catches them keeps working.

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

L<Kubernetes::REST::RemoteError> used to live in this file and now has one of
its own. Loading it from here is not possible - it inherits from this class, so
this file has to finish first - which means code that throws a C<RemoteError>
has to C<use Kubernetes::REST::RemoteError> itself. Code that only catches one
is unaffected.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST::RemoteError> - Subclass carrying the HTTP status

=back

=cut
