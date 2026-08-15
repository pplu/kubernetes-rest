package Kubernetes::REST::CLI::Role::Connection;
our $VERSION = '1.108';
# ABSTRACT: Shared kubeconfig/auth options for CLI tools
use Moo::Role;
use MooX::Options;
use Kubernetes::REST::Kubeconfig;

=head1 DESCRIPTION

Moo role providing C<--kubeconfig> and C<--context> options and a lazy C<api> attribute that builds a L<Kubernetes::REST> instance from the kubeconfig.

Consumed by L<Kubernetes::REST::CLI> and L<Kubernetes::REST::CLI::Watch>.

=cut

# Deliberately without a default: an option that always has a value is always
# passed on, and Kubernetes::REST::Kubeconfig never reaches its own default of
# $ENV{KUBECONFIG} // ~/.kube/config. Leaving it undef when the user did not ask
# for a path is what lets the environment variable through.
option kubeconfig => (
    is => 'ro',
    format => 's',
    doc => 'Path to kubeconfig file (default: $KUBECONFIG, else ~/.kube/config)',
);

=opt kubeconfig

Path to kubeconfig file. Without it the C<KUBECONFIG> environment variable is
used, and without that C<~/.kube/config> - the same precedence C<kubectl> and
L<Kubernetes::REST::Kubeconfig> apply. An explicitly given C<--kubeconfig> wins
over C<KUBECONFIG>.

C<KUBECONFIG> may name several files as the C<:>-separated list C<kubectl>
merges, in which case they are merged the same way - see
L<Kubernetes::REST::Kubeconfig/MERGING>. C<--kubeconfig> takes such a list too,
since it is passed straight through.

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
        # kubeconfig_path is only passed when --kubeconfig was given, so an
        # unset option falls through to Kubeconfig's own $ENV{KUBECONFIG}
        # default rather than being overridden by a home-directory guess.
        my $kc = Kubernetes::REST::Kubeconfig->new(
            (defined $self->kubeconfig ? (kubeconfig_path => $self->kubeconfig) : ()),
            ($self->context ? (context_name => $self->context) : ()),
        );
        return $kc->api;
    },
);

=attr api

Lazy L<Kubernetes::REST> instance built from the kubeconfig.

The kubeconfig it is built from is C<--kubeconfig> if given, otherwise
C<$ENV{KUBECONFIG}>, otherwise C<~/.kube/config>. Either of the first two may
be a C<:>-separated list of files, which is merged as C<kubectl> merges it.

=cut

1;

=seealso

=over

=item * L<Kubernetes::REST::Kubeconfig> - Kubeconfig parser

=item * L<Kubernetes::REST::CLI> - CLI base class

=item * L<Kubernetes::REST::CLI::Watch> - Watch CLI tool

=back

=cut
