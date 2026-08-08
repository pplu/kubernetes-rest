package Kubernetes::REST::CLI::Cmd::Delete;
our $VERSION = '1.106';
# ABSTRACT: The delete command of kube_client
use Moo;
use MooX::Cmd;

=head1 SYNOPSIS

    kube_client delete <Kind> <name>

=head1 DESCRIPTION

Implements the C<delete> command of L<Kubernetes::REST::CLI>. Both the kind and
the name are required - this command never deletes a whole list. L<MooX::Cmd>
finds and loads this class, you do not use it directly.

=cut

sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];

    my ($kind, $name) = @$args;

    unless ($kind && $name) {
        print STDERR "Usage: kube_client delete <Kind> <name>\n";
        return 1;
    }

    my $result = $root->api->delete($kind, $name, namespace => $root->namespace);
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
