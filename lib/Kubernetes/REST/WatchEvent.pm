package Kubernetes::REST::WatchEvent;
# ABSTRACT: A single event from the Kubernetes Watch API
use Moo;
use Types::Standard qw(Str);

has type => (is => 'ro', isa => Str, required => 1);
has object => (is => 'ro', required => 1);
has raw => (is => 'ro', required => 1);

1;

__END__

=encoding UTF-8

=head1 NAME

Kubernetes::REST::WatchEvent - A single event from the Kubernetes Watch API

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

Represents a single watch event from the Kubernetes API. Watch events are
streamed as newline-delimited JSON objects with a C<type> field and an
C<object> field.

=attr type

The event type string. One of: C<ADDED>, C<MODIFIED>, C<DELETED>, C<ERROR>,
or C<BOOKMARK>.

=attr object

The inflated L<IO::K8s> object for the resource. For C<ERROR> events this
is a hashref (the Kubernetes Status object).

=attr raw

The original hashref from the JSON before inflation. Useful for accessing
fields that may not be mapped to the IO::K8s class.

=head1 SEE ALSO

L<Kubernetes::REST/watch>, L<https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes>

=cut
