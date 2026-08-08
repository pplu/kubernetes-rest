package Kubernetes::REST::CLI::Cmd::Get;
our $VERSION = '1.106';
# ABSTRACT: The get command of kube_client
use Moo;
use MooX::Cmd;

=head1 SYNOPSIS

    kube_client get <Kind> [name] [options]

=head1 DESCRIPTION

Implements the C<get> command of L<Kubernetes::REST::CLI>. Without a name it
lists the resources of that kind in the namespace, with a name it fetches that
one resource. L<MooX::Cmd> finds and loads this class, you do not use it
directly.

=cut

sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];

    my ($kind, $name) = @$args;

    unless ($kind) {
        print STDERR "Usage: kube_client get <Kind> [name]\n";
        return 1;
    }

    my $result;
    if ($name) {
        $result = $root->api->get($kind, $name, namespace => $root->namespace);
    } else {
        $result = $root->api->list($kind, namespace => $root->namespace);
    }

    $root->format_output($result);
    return 0;
}

=method execute

Runs the command. Called by L<MooX::Cmd> with the remaining arguments and the
command chain, whose first element is the L<Kubernetes::REST::CLI> root object.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST::CLI> - CLI base class

=back

=cut
