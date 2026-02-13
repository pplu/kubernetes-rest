package Kubernetes::REST::Kubeconfig;
# ABSTRACT: Parse kubeconfig files and create Kubernetes::REST instances

use Moo;
use Carp qw(croak);
use YAML::XS ();
use Path::Tiny qw(path);
use MIME::Base64 qw(decode_base64);
use File::Temp qw(tempfile);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use namespace::clean;

=head1 SYNOPSIS

    use Kubernetes::REST::Kubeconfig;

    # Use default kubeconfig and current context
    my $kc = Kubernetes::REST::Kubeconfig->new;
    my $api = $kc->api;

    # Specify kubeconfig and context
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => '/path/to/kubeconfig',
        context_name => 'my-cluster',
    );

    # List available contexts
    my $contexts = $kc->contexts;

    # Get API for specific context
    my $api = $kc->api('production');

=head1 DESCRIPTION

Parses Kubernetes kubeconfig files (typically C<~/.kube/config>) and creates configured L<Kubernetes::REST> instances.

Supports:

=over 4

=item * Multiple clusters and contexts

=item * Token authentication

=item * Client certificate authentication

=item * Inline certificate data (base64 encoded)

=item * External certificate files

=item * Exec-based credential plugins

=back

=cut

has kubeconfig_path => (
    is => 'ro',
    default => sub { "$ENV{HOME}/.kube/config" },
);

=attr kubeconfig_path

Path to the kubeconfig file. Defaults to C<~/.kube/config>.

=cut

has context_name => (
    is => 'ro',
    predicate => 1,
);

=attr context_name

Optional. The context name to use. If not specified, uses the current-context from the kubeconfig.

=cut

has _config => (
    is => 'lazy',
    builder => sub {
        my $self = shift;
        my $path = $self->kubeconfig_path;
        croak "Kubeconfig not found: $path" unless -f $path;
        return YAML::XS::LoadFile($path);
    },
);

has _temp_files => (
    is => 'ro',
    default => sub { [] },
);

sub current_context_name {
    my $self = shift;
    return $self->context_name if $self->has_context_name;
    return $self->_config->{'current-context'};
}

=method current_context_name

    my $name = $kc->current_context_name;

Returns the current context name (either from C<context_name> attribute or from the kubeconfig's C<current-context>).

=cut

sub contexts {
    my $self = shift;
    return [ map { $_->{name} } @{$self->_config->{contexts} // []} ];
}

=method contexts

    my $contexts = $kc->contexts;

Returns an arrayref of all available context names from the kubeconfig.

=cut

sub _find_by_name {
    my ($self, $list, $name) = @_;
    for my $item (@{$list // []}) {
        return $item if $item->{name} eq $name;
    }
    return undef;
}

sub context {
    my ($self, $name) = @_;
    $name //= $self->current_context_name;
    my $ctx = $self->_find_by_name($self->_config->{contexts}, $name)
        or croak "Context not found: $name";
    return $ctx->{context};
}

sub cluster {
    my ($self, $name) = @_;
    my $cluster = $self->_find_by_name($self->_config->{clusters}, $name)
        or croak "Cluster not found: $name";
    return $cluster->{cluster};
}

sub user {
    my ($self, $name) = @_;
    my $user = $self->_find_by_name($self->_config->{users}, $name)
        or croak "User not found: $name";
    return $user->{user};
}

sub _write_temp_file {
    my ($self, $data) = @_;
    my ($fh, $filename) = tempfile(UNLINK => 0);
    print $fh $data;
    close $fh;
    push @{$self->_temp_files}, $filename;
    return $filename;
}

sub _resolve_data_or_file {
    my ($self, $hash, $key) = @_;

    # Try data first (base64 encoded)
    my $data_key = "${key}-data";
    if (my $data = $hash->{$data_key}) {
        return $self->_write_temp_file(decode_base64($data));
    }

    # Then try file path
    return $hash->{$key};
}

sub api {
    my ($self, $context_name) = @_;
    $context_name //= $self->current_context_name;

=method api

    my $api = $kc->api;
    my $api = $kc->api('production');

Create a L<Kubernetes::REST> instance configured from the kubeconfig. If C<$context_name> is provided, uses that context; otherwise uses the current context.

Automatically resolves:

=over 4

=item * Server endpoint and SSL settings

=item * Authentication credentials (token or exec plugin)

=item * Client certificates (from files or inline base64 data)

=item * CA certificate for server verification

=back

=cut

    my $ctx = $self->context($context_name);
    my $cluster = $self->cluster($ctx->{cluster});
    my $user = $self->user($ctx->{user});

    # Build server config
    my %server = (
        endpoint => $cluster->{server},
    );

    if (my $ca = $self->_resolve_data_or_file($cluster, 'certificate-authority')) {
        $server{ssl_ca_file} = $ca;
    }

    if ($cluster->{'insecure-skip-tls-verify'}) {
        $server{ssl_verify_server} = 0;
    } else {
        $server{ssl_verify_server} = 1;
    }

    if (my $cert = $self->_resolve_data_or_file($user, 'client-certificate')) {
        $server{ssl_cert_file} = $cert;
    }

    if (my $key = $self->_resolve_data_or_file($user, 'client-key')) {
        $server{ssl_key_file} = $key;
    }

    # Build credentials
    my $credentials;
    if (my $token = $user->{token}) {
        $credentials = Kubernetes::REST::AuthToken->new(token => $token);
    } elsif (my $exec = $user->{exec}) {
        $credentials = $self->_exec_credential($exec);
    } else {
        # No token auth, might be using client certs only
        $credentials = Kubernetes::REST::AuthToken->new(token => '');
    }

    return Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(%server),
        credentials => $credentials,
    );
}

sub _exec_credential {
    my ($self, $exec) = @_;

    my $cmd = $exec->{command};
    my @args = @{$exec->{args} // []};

    # Set up environment
    local %ENV = %ENV;
    for my $env (@{$exec->{env} // []}) {
        $ENV{$env->{name}} = $env->{value};
    }

    my $output = `$cmd @args`;
    croak "exec credential command failed: $cmd" if $?;

    my $cred = YAML::XS::Load($output);
    my $token = $cred->{status}{token}
        or croak "exec credential did not return token";

    return Kubernetes::REST::AuthToken->new(token => $token);
}

sub DEMOLISH {
    my $self = shift;
    # Clean up temp files
    for my $file (@{$self->_temp_files}) {
        unlink $file if -f $file;
    }
}

1;

=seealso

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::Server> - Server configuration

=item * L<Kubernetes::REST::AuthToken> - Authentication credentials

=back

=cut
