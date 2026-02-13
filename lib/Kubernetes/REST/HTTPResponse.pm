package Kubernetes::REST::HTTPResponse;
  use Moo;
  use Types::Standard qw/Str Int/;

  has content => (is => 'ro', isa => Str);
  has status => (is => 'ro', isa => Int);

1;

=encoding UTF-8

=head1 NAME

Kubernetes::REST::HTTPResponse - HTTP response object

=head1 SYNOPSIS

    use Kubernetes::REST::HTTPResponse;

    my $res = Kubernetes::REST::HTTPResponse->new(
        status => 200,
        content => '{"items":[]}',
    );

=head1 DESCRIPTION

Internal HTTP response object used by L<Kubernetes::REST>.

=attr content

The response body content.

=attr status

The HTTP status code (e.g., 200, 404, 500).

=cut
