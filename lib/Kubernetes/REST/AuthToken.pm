package Kubernetes::REST::AuthToken;
our $VERSION = '1.001';
# ABSTRACT: Kubernetes API authentication token
use Moo;
use Types::Standard qw/Str/;

=head1 SYNOPSIS

    use Kubernetes::REST::AuthToken;

    my $auth = Kubernetes::REST::AuthToken->new(
        token => $bearer_token,
    );

=head1 DESCRIPTION

Authentication credentials for Kubernetes API requests using bearer token authentication.

=cut

has token => (is => 'ro', isa => Str, required => 1);

=attr token

Required. The bearer token for API authentication.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::Kubeconfig> - Load token from kubeconfig

=back

=cut
