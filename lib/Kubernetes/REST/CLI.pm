package Kubernetes::REST::CLI;
# ABSTRACT: CLI base class for Kubernetes::REST command-line tools
our $VERSION = '1.001';
use Moo;
use MooX::Options;
use MooX::Cmd;
use JSON::MaybeXS;

with 'Kubernetes::REST::CLI::Role::Connection';

=head1 SYNOPSIS

    kube_client <command> [options]

    # Get resources
    kube_client get Pod my-pod -n default
    kube_client get Deployment --output yaml

    # Create from file
    kube_client create -f deployment.yaml

    # Delete resources
    kube_client delete Pod my-pod -n default

=head1 DESCRIPTION

Base class for the C<kube_client> command-line tool. Provides common functionality for managing Kubernetes resources from the command line.

This tool uses L<Kubernetes::REST::Kubeconfig> to connect to the cluster, so it reads from C<~/.kube/config> by default.

=head1 COMMANDS

=head2 get

    kube_client get <Kind> [name] [options]

Get a resource or list resources.

=over

=item B<get Pod> - List all pods in the namespace

=item B<get Pod my-pod> - Get a specific pod

=item B<--output json> (default) - JSON output

=item B<--output yaml> - YAML output

=item B<--output name> - Names only

=back

=head2 create

    kube_client create -f <file>

Create a resource from a YAML or JSON file. Use C<-f -> to read from stdin.

=head2 delete

    kube_client delete <Kind> <name> [options]

Delete a resource by name.

=head2 raw

    kube_client raw <Group> <Method> [key=value ...]

Make a raw v0 API call (DEPRECATED).

=head1 GLOBAL OPTIONS

=opt --namespace

Namespace for namespaced resources. Defaults to C<default>.

Short form: C<-n>

=cut

option namespace => (
    is => 'ro',
    format => 's',
    short => 'n',
    default => sub { 'default' },
    doc => 'Namespace for namespaced resources',
);

=opt --output

Output format. One of: C<json>, C<yaml>, C<name>.

Defaults to C<json>.

Short form: C<-o>

=cut

option output => (
    is => 'ro',
    format => 's',
    short => 'o',
    default => sub { 'json' },
    doc => 'Output format: json, yaml, name',
);

has json => (
    is => 'ro',
    default => sub { JSON::MaybeXS->new->pretty->canonical },
);

=attr json

L<JSON::MaybeXS> encoder instance for JSON output.

=cut

sub format_output {
    my ($self, $result) = @_;
    return unless defined $result;

    my $format = $self->output;

    if ($format eq 'json') {
        my $data = ref($result) && $result->can('TO_JSON') ? $result->TO_JSON : $result;
        print $self->json->encode($data);
    } elsif ($format eq 'yaml') {
        require YAML::XS;
        my $data = ref($result) && $result->can('TO_JSON') ? $result->TO_JSON : $result;
        print YAML::XS::Dump($data);
    } elsif ($format eq 'name') {
        if (ref($result) && $result->can('items')) {
            for my $item (@{$result->items // []}) {
                my $meta = $item->metadata;
                my $ns = $meta->namespace ? $meta->namespace . '/' : '';
                print $ns, $meta->name, "\n";
            }
        } elsif (ref($result) && $result->can('metadata')) {
            my $meta = $result->metadata;
            my $ns = $meta->namespace ? $meta->namespace . '/' : '';
            print $ns, $meta->name, "\n";
        }
    } else {
        require Data::Dumper;
        print Data::Dumper::Dumper($result);
    }
}

=method format_output

    $cli->format_output($result);

Format and print the result according to the C<--output> option.

=cut

sub execute {
    my ($self, $args, $chain) = @_;
    print "Usage: kube_client <command> [options]\n\n";
    print "Commands:\n";
    print "  get <Kind> [name]     Get resource(s)\n";
    print "  create -f <file>      Create resource from file\n";
    print "  delete <Kind> <name>  Delete resource\n";
    print "  raw <Group> <Method>  Raw API call\n";
    print "\nRun 'kube_client --help' for options.\n";
    print "See also: kube_watch <Kind> for live event streaming.\n";
    return 0;
}

=method execute

Default execute method. Prints usage information.

=cut

=seealso

=over

=item * L<Kubernetes::REST> - Main API module

=item * L<Kubernetes::REST::CLI::Watch> - Watch command implementation

=item * L<Kubernetes::REST::CLI::Role::Connection> - Connection options

=back

=cut

1;

package Kubernetes::REST::CLI::Cmd::Get;
our $VERSION = '1.001';
use Moo;
use MooX::Cmd;

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

1;

package Kubernetes::REST::CLI::Cmd::Create;
our $VERSION = '1.001';
use Moo;
use MooX::Options;
use MooX::Cmd;

option file => (
    is => 'ro',
    format => 's',
    short => 'f',
    doc => 'File to read (- for stdin)',
    default => sub { '-' },
);

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

1;

package Kubernetes::REST::CLI::Cmd::Delete;
our $VERSION = '1.001';
use Moo;
use MooX::Cmd;

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

1;

package Kubernetes::REST::CLI::Cmd::Raw;
our $VERSION = '1.001';
use Moo;
use MooX::Cmd;

sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];

    my ($group, $method, @rest) = @$args;

    unless ($group && $method) {
        print STDERR "Usage: kube_client raw <Group> <Method> [key=value ...]\n";
        print STDERR "Example: kube_client raw CoreV1 ListNamespace\n";
        return 1;
    }

    my %params;
    for my $arg (@rest) {
        if ($arg =~ /^([^=]+)=(.*)$/) {
            $params{$1} = $2;
        } else {
            print STDERR "Invalid argument: $arg (expected key=value)\n";
            return 1;
        }
    }

    my $result = $root->api->$group->$method(%params);
    $root->format_output($result);
    return 0;
}

1;
