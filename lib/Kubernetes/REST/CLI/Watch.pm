package Kubernetes::REST::CLI::Watch;
# ABSTRACT: CLI for watching Kubernetes resources
use Moo;
use MooX::Options;
use JSON::MaybeXS;
use POSIX qw(strftime);

with 'Kubernetes::REST::CLI::Role::Connection';

option namespace => (
    is => 'ro',
    format => 's',
    short => 'n',
    doc => 'Namespace to watch',
);

option output => (
    is => 'ro',
    format => 's',
    short => 'o',
    default => sub { 'text' },
    doc => 'Output format: text, json, yaml',
);

option timeout => (
    is => 'ro',
    format => 'i',
    short => 't',
    default => sub { 300 },
    doc => 'Server-side timeout per watch cycle (seconds)',
);

option event_type => (
    is => 'ro',
    format => 's',
    short => 'T',
    doc => 'Only show these event types (comma-separated)',
);

option label => (
    is => 'ro',
    format => 's',
    short => 'l',
    doc => 'Label selector',
);

option field => (
    is => 'ro',
    format => 's',
    short => 'f',
    doc => 'Field selector',
);

option names => (
    is => 'ro',
    format => 's',
    short => 'N',
    doc => 'Filter by resource name (Perl regex)',
);

option timestamp_format => (
    is => 'ro',
    format => 's',
    short => 'F',
    default => sub { 'datetime' },
    doc => 'Timestamp format: datetime, date, time, epoch, iso',
);

has _json => (
    is => 'ro',
    default => sub { JSON::MaybeXS->new->canonical->utf8 },
);

has _type_filter => (
    is => 'lazy',
    default => sub {
        my $self = shift;
        return {} unless $self->event_type;
        return { map { uc($_) => 1 } split /,/, $self->event_type };
    },
);

has _name_re => (
    is => 'lazy',
    default => sub {
        my $self = shift;
        return undef unless $self->names;
        my $re = eval { qr/${\$self->names}/ };
        die "Invalid --names regex '" . $self->names . "': $@\n" if $@;
        return $re;
    },
);

my %TS_FORMATS = (
    datetime => '%Y-%m-%d %H:%M:%S',
    date     => '%Y-%m-%d',
    time     => '%H:%M:%S',
    iso      => '%Y-%m-%dT%H:%M:%S%z',
);

sub _timestamp {
    my ($self) = @_;
    my $fmt = $self->timestamp_format;
    return time if $fmt eq 'epoch';
    my $strftime_fmt = $TS_FORMATS{$fmt}
        // die "Unknown --timestamp-format '$fmt' (use: datetime, date, time, epoch, iso)\n";
    return strftime($strftime_fmt, localtime);
}

sub run {
    my ($self, $kind) = @_;

    unless ($kind) {
        die "Usage: kube_watch [options] <Kind>\n"
            . "Run 'kube_watch --help' for options.\n";
    }

    my $rv;
    while (1) {
        $rv = eval {
            $self->api->watch($kind,
                ($self->namespace ? (namespace       => $self->namespace) : ()),
                ($rv              ? (resourceVersion => $rv)              : ()),
                ($self->label     ? (labelSelector   => $self->label)    : ()),
                ($self->field     ? (fieldSelector   => $self->field)    : ()),
                timeout  => $self->timeout,
                on_event => sub { $self->_handle_event(@_) },
            );
        };
        if ($@) {
            if ($@ =~ /410 Gone/) {
                warn "Watch expired, re-listing...\n";
                $rv = undef;
                next;
            }
            die "Watch error: $@\n";
        }
        # Normal timeout, restart watch
    }
}

sub _handle_event {
    my ($self, $event) = @_;
    my $type = $event->type;

    # Type filter
    my $tf = $self->_type_filter;
    if (%$tf && !$tf->{$type}) {
        return;
    }

    # Name filter
    my $name_re = $self->_name_re;
    if ($name_re) {
        my $name = eval { $event->object->metadata->name }
            // $event->raw->{metadata}{name} // '';
        return unless $name =~ $name_re;
    }

    if ($self->output eq 'json') {
        print $self->_json->encode({
            type   => $type,
            object => $event->raw,
        }), "\n";
    } elsif ($self->output eq 'yaml') {
        require YAML::XS;
        print YAML::XS::Dump({
            type   => $type,
            object => $event->raw,
        });
        print "---\n";
    } else {
        $self->_print_text($event);
    }
}

sub _print_text {
    my ($self, $event) = @_;
    my $type = $event->type;
    my $ts = $self->_timestamp;
    my $obj = $event->object;

    if ($type eq 'ERROR') {
        my $msg  = $event->raw->{message} // 'unknown error';
        my $code = $event->raw->{code}    // '?';
        printf "%s  %-10s  ERROR(%s): %s\n", $ts, $type, $code, $msg;
        return;
    }

    my $name = eval { $obj->metadata->name }      // '?';
    my $ns   = eval { $obj->metadata->namespace }  // '';
    my $qualified = $ns ? "$ns/$name" : $name;

    # Try to get a useful status hint
    my $hint = '';
    if ($obj->can('status')) {
        my $status = eval { $obj->status };
        if ($status) {
            $hint = eval { $status->phase } // '';
            if (!$hint && $status->can('readyReplicas')) {
                my $ready   = eval { $status->readyReplicas } // 0;
                my $desired = eval { $obj->spec->replicas }   // '?';
                $hint = "${ready}/${desired} ready";
            }
        }
    }

    printf "%s  %-10s  %-50s  %s\n", $ts, $type, $qualified, $hint;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Kubernetes::REST::CLI::Watch - CLI for watching Kubernetes resources

=head1 SYNOPSIS

    use Kubernetes::REST::CLI::Watch;

    my $watcher = Kubernetes::REST::CLI::Watch->new_with_options;
    $watcher->run($ARGV[0]);

=head1 DESCRIPTION

MooX::Options-based class that powers the L<kube_watch> CLI tool. Uses
L<Kubernetes::REST::CLI::Role::Connection> for shared kubeconfig/auth
handling.

=attr namespace

Namespace to watch. Omit for cluster-scoped resources or to watch all namespaces.

=attr output

Output format: C<text> (default), C<json>, or C<yaml>.

=attr timeout

Server-side timeout per watch cycle in seconds. Default: 300.

=attr event_type

Comma-separated list of event types to show (e.g., C<ADDED,DELETED>).

=attr label

Label selector to filter resources.

=attr field

Field selector to filter resources.

=attr names

Perl regex to filter by resource name.

=attr timestamp_format

Timestamp format for text output. One of:

=over 4

=item C<datetime> (default) - C<2025-02-12 14:23:01>

=item C<date> - C<2025-02-12>

=item C<time> - C<14:23:01>

=item C<epoch> - C<1707745381>

=item C<iso> - C<2025-02-12T14:23:01+0100>

=back

=head1 SEE ALSO

L<kube_watch>, L<Kubernetes::REST/watch>, L<Kubernetes::REST::CLI::Role::Connection>

=cut
