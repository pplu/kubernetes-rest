package Kubernetes::REST::AuthExec;
our $VERSION = '1.110';
# ABSTRACT: Bearer token from an exec credential plugin, run again before it expires
use Moo;
use Carp qw(carp croak);
use POSIX ();
use Time::Local qw(timegm);
use YAML::XS ();
use namespace::clean;

=head1 SYNOPSIS

    use Kubernetes::REST::AuthExec;

    my $auth = Kubernetes::REST::AuthExec->new(
        command => 'aws',
        args    => [qw( eks get-token --cluster-name prod )],
    );

    my $api = Kubernetes::REST->new(
        server      => $server,
        credentials => $auth,
    );

=head1 DESCRIPTION

Authentication credentials from a kubeconfig C<exec> block (kubectl's
exec-credential-plugin mechanism, used for cloud IAM logins such as
C<aws eks get-token>). The plugin is run when the object is built, and its
output - YAML, which also accepts the JSON real plugins emit - supplies
C<status.token> and optionally C<status.expirationTimestamp>.

The plugin is run again when the C<expirationTimestamp> lies within
L</expiry_margin> seconds of now (or already behind it). A plugin that reports
no C<expirationTimestamp> is never run a second time: the token is taken to be
valid for as long as the object lives.

The first run is fatal: the constructor dies if the plugin cannot be started,
is killed, exits non-zero, or returns no token, because there is nothing to fall
back on yet. A later run that fails only warns and the last good token stays in
use. Nothing runs the plugin again in reaction to a C<401> from the cluster; a
token the server rejects before its announced expiry stays in use until the
margin is reached.

Only token plugins are supported. A plugin that answers with
C<clientCertificateData>/C<clientKeyData> and no C<token> makes the constructor
die with C<exec credential did not return a token: only token plugins are
supported, not client certificate credentials>.

L<Kubernetes::REST> asks its C<credentials> for a C<token()> on every request,
so passing one of these is all a long-running process needs.

=cut

has command => (
    is => 'ro',
    required => 1,
);

=attr command

Required. The plugin program, run without a shell.

=cut

has args => (
    is => 'ro',
    default => sub { [] },
);

=attr args

Array reference of arguments, each one argv element. Defaults to none.

=cut

has env => (
    is => 'ro',
    default => sub { [] },
);

=attr env

Array reference of C<< { name => ..., value => ... } >> entries set in the
plugin's environment.

=cut

has expiry_margin => (
    is => 'ro',
    default => sub { 60 },
);

=attr expiry_margin

Seconds before C<expirationTimestamp> at which the plugin is run again.
Defaults to 60. Has no effect for a plugin that reports no
C<expirationTimestamp>.

=cut

has description => (
    is => 'ro',
    default => sub { 'exec credential' },
);

=attr description

How this credential is named in error messages.

=cut

has _token => (
    is => 'rw',
    init_arg => undef,
);

has _expires => (
    is => 'rw',
    init_arg => undef,
);

sub BUILD {
    my ($self) = @_;
    # The first run is fatal: nothing to fall back on yet.
    $self->_refresh;
    return;
}

sub token {
    my ($self) = @_;

=method token

    my $token = $auth->token;

The bearer token. Runs the plugin again when its expirationTimestamp is within
C<expiry_margin> seconds; without an expirationTimestamp the token is never
renewed. A failed re-run warns and keeps the last good token.

=cut

    my $expires = $self->_expires;
    if (defined $expires and $expires - time <= $self->expiry_margin) {
        eval { $self->_refresh; 1 }
            or carp 'Cannot renew the ' . $self->description . ': ' . $@;
    }
    return $self->_token;
}

sub _refresh {
    my ($self) = @_;
    my $cred = YAML::XS::Load($self->_run_plugin);
    my $status = ref $cred eq 'HASH' ? ($cred->{status} // {}) : {};

    my $token = $status->{token};
    unless (defined $token and length $token) {
        croak 'exec credential did not return a token: only token plugins are supported, not client certificate credentials'
            if $status->{clientCertificateData} or $status->{clientKeyData};
        croak 'exec credential did not return token';
    }

    $self->_token($token);
    $self->_expires($self->_parse_timestamp($status->{expirationTimestamp}));
    return $token;
}

# RFC3339: Z or +-hh:mm, optional fraction. Unparseable counts as no expiry.
sub _parse_timestamp {
    my ($self, $ts) = @_;
    return unless defined $ts;
    my ($y, $mo, $d, $h, $mi, $s, $zone) = "$ts" =~ /\A
        (\d{4})-(\d\d)-(\d\d) [Tt ] (\d\d):(\d\d):(\d\d) (?:\.\d+)?
        (Z|z|[+-]\d\d:?\d\d)
    \z/x or return;
    my $epoch = eval { timegm($s, $mi, $h, $d, $mo - 1, $y) };
    return unless defined $epoch;
    if ($zone =~ /\A([+-])(\d\d):?(\d\d)\z/) {
        my $offset = ($2 * 3600 + $3 * 60) * ($1 eq '-' ? -1 : 1);
        $epoch -= $offset;
    }
    return $epoch;
}

sub _run_plugin {
    my ($self) = @_;

    my $cmd = $self->command;
    my @args = @{$self->args};

    # Set up environment
    local %ENV = %ENV;
    for my $env (@{$self->env}) {
        $ENV{$env->{name}} = $env->{value};
    }

    # No shell: fork and exec with the indirect-object form, so even a bare
    # command (a one-element list, which perl would hand to /bin/sh when it
    # holds whitespace or metacharacters) is one program path and each arg is
    # exactly one argv element. stderr is inherited, so the plugin's own
    # complaint stays visible. A failed exec is reported through a pipe, as
    # perl does for the list form of open.
    pipe(my $err_r, my $err_w) or croak "exec credential pipe failed: $!";
    my $pid = open(my $fh, '-|');
    croak "exec credential command $cmd could not be started: $!"
        unless defined $pid;
    unless ($pid) {
        close $err_r;
        { exec {$cmd} $cmd, @args }
        my $errno = $! + 0;
        print {$err_w} $errno;
        close $err_w;
        POSIX::_exit(127);
    }
    close $err_w;
    my $exec_errno = do { local $/; <$err_r> };
    close $err_r;
    my $output = do { local $/; <$fh> };
    close $fh;
    my $status = $?;
    if (length $exec_errno) {
        local $! = $exec_errno;
        croak "exec credential command $cmd could not be started: $!";
    }
    croak "exec credential command $cmd was killed by signal " . ($status & 127)
        if $status & 127;
    croak "exec credential command $cmd exited with status " . ($status >> 8)
        if $status;

    return $output;
}

1;

=seealso

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::Kubeconfig> - Builds these from an C<exec> block

=item * L<Kubernetes::REST::AuthTokenFile> - The file-based counterpart

=back

=cut
