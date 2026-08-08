package Kubernetes::REST::Role::IO;
our $VERSION = '1.106';
# ABSTRACT: Interface role for HTTP backends
use Moo::Role;

=head1 SYNOPSIS

    package My::AsyncIO;
    use Moo;
    with 'Kubernetes::REST::Role::IO';

    sub call {
        my ($self, $req) = @_;
        # Execute HTTP request, return Kubernetes::REST::HTTPResponse
        ...
    }

    sub call_streaming {
        my ($self, $req, $data_callback) = @_;
        # Execute HTTP request with streaming callback
        ...
    }

    # Optional: full-duplex transport (WebSocket/SPDY)
    sub call_duplex {
        my ($self, $req, %callbacks) = @_;
        ...
    }

=head1 DESCRIPTION

This role defines the interface that HTTP backends must implement. L<Kubernetes::REST> delegates all HTTP communication through this interface, making it possible to swap out the transport layer.

The default backend is L<Kubernetes::REST::LWPIO> (using L<LWP::UserAgent>). An alternative L<Kubernetes::REST::HTTPTinyIO> (using L<HTTP::Tiny>) is provided. To use an async event loop, implement this role with e.g. L<Net::Async::HTTP>.

=cut

requires 'call';

=method call

    my $response = $io->call($req);

Required. Execute an HTTP request. Receives a L<Kubernetes::REST::HTTPRequest> with C<method>, C<url>, C<headers>, and optionally C<content> already set.

Must return a L<Kubernetes::REST::HTTPResponse> with C<status> and C<content>.

=cut

requires 'call_streaming';

=method call_streaming

    my $response = $io->call_streaming($req, $data_callback);

Required. Execute an HTTP request with streaming response. The C<$data_callback> is called with each chunk of data as it arrives: C<< $data_callback->($chunk) >>.

Must return a L<Kubernetes::REST::HTTPResponse> when the stream ends.

=cut

sub supports_duplex {
    my ($self) = @_;
    return $self->can('call_duplex') ? 1 : 0;
}

=method supports_duplex

    if ($io->supports_duplex) {
        ...
    }

Optional capability probe for full-duplex protocols used by Kubernetes
subresources such as pod port-forward and exec/attach streams.

Returns true if the backend implements C<call_duplex>, false otherwise.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::LWPIO> - LWP::UserAgent backend (default)

=item * L<Kubernetes::REST::HTTPTinyIO> - HTTP::Tiny backend

=item * L<Kubernetes::REST::HTTPRequest> - Request object

=item * L<Kubernetes::REST::HTTPResponse> - Response object

=back

=cut
