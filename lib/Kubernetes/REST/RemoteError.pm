package Kubernetes::REST::RemoteError;
our $VERSION = '1.107';
# ABSTRACT: Compatibility helper for deprecated v0 remote errors
  use Moo;
  use Types::Standard qw/Int/;
  use Kubernetes::REST::Error;
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

This error class belongs to the deprecated v0 API - the v1 API croaks instead of throwing structured exceptions. It stays around so code that still catches it keeps working.

Thrown for errors reported by the cluster itself, carrying the HTTP status alongside the message of L<Kubernetes::REST::Error>.

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST::Error> - The base error class

=back

=cut
