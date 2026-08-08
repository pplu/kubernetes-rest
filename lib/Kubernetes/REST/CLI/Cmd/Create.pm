package Kubernetes::REST::CLI::Cmd::Create;
our $VERSION = '1.106';
# ABSTRACT: The create command of kube_client
use Moo;
use MooX::Options;
use MooX::Cmd;

=head1 SYNOPSIS

    kube_client create -f <file>
    kube_client create -f -        # read from stdin

=head1 DESCRIPTION

Implements the C<create> command of L<Kubernetes::REST::CLI>. Reads a YAML or
JSON manifest, inflates it into a typed L<IO::K8s> object and creates it on the
cluster. L<MooX::Cmd> finds and loads this class, you do not use it directly.

=cut

option file => (
    is => 'ro',
    format => 's',
    short => 'f',
    doc => 'File to read (- for stdin)',
    default => sub { '-' },
);

=opt file

Path of the manifest to create, C<-> for stdin. Short form: C<-f>. Defaults to
C<->.

=cut

sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];

    my $input;
    if ($self->file eq '-') {
        local $/;
        $input = <STDIN>;
    } else {
        open my $fh, '<', $self->file or die "Cannot open " . $self->file . ": $!";
        local $/;
        $input = <$fh>;
        close $fh;
    }

    my $obj = $root->api->inflate($input);
    my $result = $root->api->create($obj);
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
