package Kubernetes::REST::Server;
our $VERSION = '1.001';
# ABSTRACT: Kubernetes API server connection configuration
use Moo;
use Types::Standard qw/Str Bool/;

=head1 SYNOPSIS

    use Kubernetes::REST::Server;

    my $server = Kubernetes::REST::Server->new(
        endpoint => 'https://kubernetes.local:6443',
        ssl_verify_server => 1,
        ssl_ca_file => '/path/to/ca.crt',
    );

=head1 DESCRIPTION

Configuration object for Kubernetes API server connection details.

=cut

has endpoint => (is => 'ro', isa => Str, required => 1);

=attr endpoint

Required. The Kubernetes API server endpoint URL (e.g., C<https://kubernetes.local:6443>).

=cut

has ssl_verify_server => (is => 'ro', isa => Bool, default => 1);

=attr ssl_verify_server

Boolean. Whether to verify the server's SSL certificate. Defaults to C<1> (true).

Set to C<0> for development clusters with self-signed certificates.

=cut

has ssl_cert_file => (is => 'ro');

=attr ssl_cert_file

Optional. Path to client certificate file for mTLS authentication.

=cut

has ssl_key_file => (is => 'ro');

=attr ssl_key_file

Optional. Path to client key file for mTLS authentication.

=cut

has ssl_ca_file => (is => 'ro');

=attr ssl_ca_file

Optional. Path to CA certificate file for verifying the server certificate.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::Kubeconfig> - Load settings from kubeconfig

=back

=cut
