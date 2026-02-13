package Kubernetes::REST::Role::IO;
# ABSTRACT: Interface role for HTTP backends
use Moo::Role;

requires 'call';
requires 'call_streaming';

1;

__END__

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Role::IO - Interface role for pluggable HTTP backends

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

=head1 DESCRIPTION

This role defines the interface that HTTP backends must implement.
L<Kubernetes::REST> delegates all HTTP communication through this
interface, making it possible to swap out the transport layer.

The default backend is L<Kubernetes::REST::HTTPTinyIO> (synchronous,
using L<HTTP::Tiny>). To use an async event loop, implement this role
with e.g. L<Net::Async::HTTP>.

=head1 REQUIRED METHODS

=head2 call($req)

Execute an HTTP request. Receives a L<Kubernetes::REST::HTTPRequest> with
C<method>, C<url>, C<headers>, and optionally C<content> already set.

Must return a L<Kubernetes::REST::HTTPResponse> with C<status> and C<content>.

=head2 call_streaming($req, $data_callback)

Execute an HTTP request with streaming response. The C<$data_callback>
is called with each chunk of data as it arrives: C<< $data_callback->($chunk) >>.

Query parameters from C<< $req->parameters >> should be appended to the URL.

Must return a L<Kubernetes::REST::HTTPResponse> when the stream ends.

=head1 SEE ALSO

L<Kubernetes::REST::HTTPTinyIO>, L<Kubernetes::REST>

=cut
