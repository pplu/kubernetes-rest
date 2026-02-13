package Kubernetes::REST::Server;
# ABSTRACT: Kubernetes API server connection configuration
  use Moo;
  use Types::Standard qw/Str Bool/;

  has endpoint => (is => 'ro', isa => Str, required => 1);

  has ssl_verify_server => (is => 'ro', isa => Bool, default => 1);
  has ssl_cert_file => (is => 'ro');
  has ssl_key_file => (is => 'ro');
  has ssl_ca_file => (is => 'ro');

1;

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Server - Kubernetes API server connection configuration

=head1 SYNOPSIS

    use Kubernetes::REST::Server;

    my $server = Kubernetes::REST::Server->new(
        endpoint => 'https://kubernetes.local:6443',
        ssl_verify_server => 1,
        ssl_ca_file => '/path/to/ca.crt',
    );

=head1 DESCRIPTION

Configuration object for Kubernetes API server connection details.

=attr endpoint

Required. The Kubernetes API server endpoint URL.

=attr ssl_verify_server

Boolean. Whether to verify the server's SSL certificate. Defaults to true.

=attr ssl_cert_file

Optional. Path to client certificate file for mTLS authentication.

=attr ssl_key_file

Optional. Path to client key file for mTLS authentication.

=attr ssl_ca_file

Optional. Path to CA certificate file for verifying the server certificate.

=cut
