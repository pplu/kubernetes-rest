package Kubernetes::REST::AuthToken;
# ABSTRACT: Kubernetes API authentication token
  use Moo;
  use Types::Standard qw/Str/;

  has token => (is => 'ro', isa => Str, required => 1);

1;

=encoding UTF-8

=head1 NAME

Kubernetes::REST::AuthToken - Kubernetes API authentication token

=head1 SYNOPSIS

    use Kubernetes::REST::AuthToken;

    my $auth = Kubernetes::REST::AuthToken->new(
        token => $bearer_token,
    );

=head1 DESCRIPTION

Authentication credentials for Kubernetes API requests using bearer token authentication.

=attr token

Required. The bearer token for API authentication.

=cut
