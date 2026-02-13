package Kubernetes::REST::CLI::Role::Connection;
# ABSTRACT: Shared kubeconfig/auth options for CLI tools
use Moo::Role;
use MooX::Options;
use Kubernetes::REST::Kubeconfig;

=head1 DESCRIPTION

Moo role providing C<--kubeconfig> and C<--context> options and a lazy C<api> attribute that builds a L<Kubernetes::REST> instance from the kubeconfig.

Consumed by L<Kubernetes::REST::CLI> and L<Kubernetes::REST::CLI::Watch>.

=cut

option kubeconfig => (
    is => 'ro',
    format => 's',
    doc => 'Path to kubeconfig file',
    default => sub { "$ENV{HOME}/.kube/config" },
);

=opt kubeconfig

Path to kubeconfig file. Defaults to C<~/.kube/config>.

=cut

option context => (
    is => 'ro',
    format => 's',
    short => 'c',
    doc => 'Kubernetes context to use',
);

=opt context

Kubernetes context to use from the kubeconfig. Defaults to the current-context.

Short option: C<-c>

=cut

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

=attr api

Lazy L<Kubernetes::REST> instance built from the kubeconfig.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST::Kubeconfig> - Kubeconfig parser

=item * L<Kubernetes::REST::CLI> - CLI base class

=item * L<Kubernetes::REST::CLI::Watch> - Watch CLI tool

=back

=cut
