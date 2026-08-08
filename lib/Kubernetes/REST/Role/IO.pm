package Kubernetes::REST::Role::IO;
our $VERSION = '1.107';
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

=head2 Encoding contract

Request and response bodies are B<bytes>, never character strings.

A backend receives C<< $req->content >> already UTF-8 encoded and must put it on
the wire unchanged. It must hand back C<< $res->content >> - and every streaming
chunk - as the bytes it received, undoing C<Content-Encoding> (gzip) but B<not>
the charset. L<Kubernetes::REST> decodes UTF-8 itself, together with L<IO::K8s>,
so a backend that decodes on its own causes silent double decoding (mojibake) on
any non-ASCII value.

With L<LWP::UserAgent> that means C<< $res->decoded_content(charset => 'none') >>
rather than C<< $res->decoded_content >>.

=cut

requires 'call';

=method call

    my $response = $io->call($req);

Required. Execute an HTTP request. Receives a L<Kubernetes::REST::HTTPRequest> with C<method>, C<url>, C<headers>, and optionally C<content> already set.

Must return a L<Kubernetes::REST::HTTPResponse> with C<status> and C<content>, the latter as bytes - see L</Encoding contract>.

=cut

requires 'call_streaming';

=method call_streaming

    my $response = $io->call_streaming($req, $data_callback);

Required. Execute an HTTP request with streaming response. The C<$data_callback> is called with each chunk of data as it arrives: C<< $data_callback->($chunk) >>. Chunks are bytes - see L</Encoding contract>.

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
