package Kubernetes::REST::WatchEvent;
our $VERSION = '1.001';
# ABSTRACT: A single event from the Kubernetes Watch API
use Moo;
use Types::Standard qw(Str);

=head1 SYNOPSIS

    $api->watch('Pod',
        namespace => 'default',
        on_event  => sub {
            my ($event) = @_;
            say $event->type;             # ADDED, MODIFIED, DELETED, ERROR, BOOKMARK
            say $event->object->metadata->name;  # inflated IO::K8s object
            say $event->raw->{metadata}{name};    # original hashref
        },
    );

=head1 DESCRIPTION

Represents a single watch event from the Kubernetes API. Watch events are streamed as newline-delimited JSON objects with a C<type> field and an C<object> field.

=cut

has type => (is => 'ro', isa => Str, required => 1);

=attr type

The event type string. One of: C<ADDED>, C<MODIFIED>, C<DELETED>, C<ERROR>, or C<BOOKMARK>.

=cut

has object => (is => 'ro', required => 1);

=attr object

The inflated L<IO::K8s> object for the resource. For C<ERROR> events this is a hashref (the Kubernetes Status object).

=cut

has raw => (is => 'ro', required => 1);

=attr raw

The original hashref from the JSON before inflation. Useful for accessing fields that may not be mapped to the L<IO::K8s> class.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST/watch> - Watch API documentation

=item * L<https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes> - Kubernetes watch documentation

=back

=cut
