package Kubernetes::REST::CLI::Role::Connection;
# ABSTRACT: Shared kubeconfig/auth options for CLI tools
use Moo::Role;
use MooX::Options;
use Kubernetes::REST::Kubeconfig;

option kubeconfig => (
    is => 'ro',
    format => 's',
    doc => 'Path to kubeconfig file',
    default => sub { "$ENV{HOME}/.kube/config" },
);

option context => (
    is => 'ro',
    format => 's',
    short => 'c',
    doc => 'Kubernetes context to use',
);

has api => (
    is => 'lazy',
    builder => sub {
        my $self = shift;
        my $kc = Kubernetes::REST::Kubeconfig->new(
            kubeconfig_path => $self->kubeconfig,
            ($self->context ? (context_name => $self->context) : ()),
        );
        return $kc->api;
    },
);

1;

__END__

=encoding UTF-8

=head1 NAME

Kubernetes::REST::CLI::Role::Connection - Shared kubeconfig/auth options for CLI tools

=head1 DESCRIPTION

Moo role providing C<--kubeconfig> and C<--context> options and a lazy
C<api> attribute that builds a L<Kubernetes::REST> instance from the
kubeconfig. Consumed by L<Kubernetes::REST::CLI> and
L<Kubernetes::REST::CLI::Watch>.

=attr kubeconfig

Path to kubeconfig file. Defaults to C<~/.kube/config>.

=attr context

Kubernetes context to use from the kubeconfig. Defaults to the
current-context.

=attr api

Lazy L<Kubernetes::REST> instance built from the kubeconfig.

=cut
