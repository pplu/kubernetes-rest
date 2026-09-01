package Kubernetes::REST::LogEvent;
our $VERSION = '1.108';
# ABSTRACT: A single log line from the Kubernetes Pod Log API
use Moo;
use Types::Standard qw(Str);

=head1 SYNOPSIS

    $api->log('Pod', 'my-pod',
        namespace => 'default',
        follow    => 1,
        on_line   => sub {
            my ($event) = @_;
            say $event->line;
        },
    );

=head1 DESCRIPTION

Represents a single log line from the Kubernetes Pod Log API. Wraps the raw text line in a typed object for consistent event handling, analogous to L<Kubernetes::REST::WatchEvent> for the Watch API.

=cut

has line => (is => 'ro', isa => Str, required => 1);

=attr line

Required. The log line text. Does not include the trailing newline.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST/log> - Pod Log API documentation

=item * L<Kubernetes::REST::WatchEvent> - Analogous event object for the Watch API

=item * L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#read-log-pod-v1-core> - Kubernetes Pod log API reference

=back

=cut
