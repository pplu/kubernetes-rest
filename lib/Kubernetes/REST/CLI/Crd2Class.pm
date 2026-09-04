package Kubernetes::REST::CLI::Crd2Class;
our $VERSION = '1.108';
# ABSTRACT: Generate IO::K8s classes from a CustomResourceDefinition
use Moo;
use MooX::Options;
use Carp qw( croak );
use Path::Tiny qw( path );
use IO::K8s::CRD ();
use IO::K8s::CRD::Emitter ();

=head1 SYNOPSIS

    use Kubernetes::REST::CLI::Crd2Class;

    my $cli = Kubernetes::REST::CLI::Crd2Class->new_with_options;
    exit $cli->run;

=head1 DESCRIPTION

L<MooX::Options>-based class that powers the L<kube_crd2class> CLI tool: the
D15 wrapper around the D10 source emitter. It reads a
C<CustomResourceDefinition> from a file and prints, for every B<served>
version, the checked-in, documented L<IO::K8s> class source that models it -
the C<k8s> DSL block plus a POD skeleton - so a cluster's CRDs can become
typed, hand-maintained Perl classes without writing them by hand (the
kopium / C<cdk8s import> path).

The schema-to-DSL work is entirely L<IO::K8s>'s: L<IO::K8s::CRD/load>,
L<IO::K8s::CRD/served_versions> and L<IO::K8s::CRD/generate> build the
classes and L<IO::K8s::CRD::Emitter/render> renders them. This class is only
the CLI hull: file in, emitter, source out.

The C<-f> path never talks to a cluster and does not consume
L<Kubernetes::REST::CLI::Role::Connection> - no kubeconfig is read. The
C</from_cluster> path, which needs aggregated discovery from a live cluster,
is scaffolded but B<not yet implemented>: it dies with a clear message. It
lands with the discovery work of the same CRD design increment (D11/D16).

=cut

option file => (
    is => 'ro',
    format => 's',
    short => 'f',
    doc => 'Path to a CustomResourceDefinition YAML/JSON file',
);

=opt file

Path to a file holding one or more C<CustomResourceDefinition> manifests
(YAML, possibly multi-document, or JSON). Every served version of every CRD
in the file is turned into class source.

Short option: C<-f>

=cut

option namespace => (
    is => 'ro',
    format => 's',
    short => 'n',
    doc => 'Base package for the generated classes (default: derived from the CRD group)',
);

=opt namespace

The base package the generated classes are rendered under, without the
version segment: C<IO::K8s::MyProvider> yields C<IO::K8s::MyProvider::V1::Kind>
for a served C<v1>. When omitted a default is derived from the CRD group's
leading DNS label (C<cert-manager.io> becomes C<IO::K8s::CertManager>). Per
served version the version name is appended, C<< ucfirst >>-ed the way the
D6 provider namespaces are (C<v1alpha1> becomes C<V1alpha1>).

Short option: C<-n>

=cut

option output_dir => (
    is => 'ro',
    format => 's',
    short => 'd',
    doc => 'Write the .pm files under this directory instead of printing them',
);

=opt output_dir

When set, each rendered class is written to
F<E<lt>output_dirE<gt>/E<lt>relative/pathE<gt>.pm> (intermediate directories
created) instead of being printed to STDOUT, and the path written is logged to
STDERR. Without it every class is printed to STDOUT, each under a banner
naming its relative path and the C<apiVersion> it models.

Short option: C<-d>

=cut

option from_cluster => (
    is => 'ro',
    format => 's',
    doc => 'NOT YET IMPLEMENTED: generate from a Kind served by a live cluster',
);

=opt from_cluster

B<Not yet implemented.> The scaffolded option for generating classes from a
Kind a live cluster already serves, using aggregated discovery to find its
CRD. Supplying it dies with a clear message; it lands together with the
discovery work of the same CRD design increment (D11/D16). Use L</file> until
then.

=cut

=method run

    my $exit_code = $cli->run;

Entry point called by C<bin/kube_crd2class>. Loads the L</file> CRD, and for
every served version of every CRD in it renders the L<IO::K8s> class source
through L<IO::K8s::CRD::Emitter> - printing it to STDOUT, or writing it under
L</output_dir> when that is set. Returns 0.

Dies with a clear "not yet implemented" message when L</from_cluster> is
given, and with usage guidance when neither input is supplied.

=cut

sub run {
    my ($self) = @_;

    if (defined $self->from_cluster && length $self->from_cluster) {
        croak "kube_crd2class: --from-cluster is not yet implemented; it needs "
            . "aggregated cluster discovery (CRD design D11/D16). Use --file/-f "
            . "with a CustomResourceDefinition manifest for now.\n";
    }

    my $file = $self->file;
    croak "kube_crd2class: no input given; pass --file/-f <crd.yaml>\n"
        unless defined $file && length $file;
    croak "kube_crd2class: no such file: $file\n" unless -f $file;

    binmode STDOUT, ':encoding(UTF-8)';

    my $crds  = IO::K8s::CRD->load($file);
    my $files = $self->_render_crds($crds);

    if (defined $self->output_dir && length $self->output_dir) {
        $self->_write_files($files);
    }
    else {
        $self->_print_files($files);
    }
    return 0;
}

# An arrayref of [ relative_path, api_version, source ] blocks for every
# served version of every loaded CRD, in manifest order - the whole
# schema-to-DSL job delegated to IO::K8s (load/served_versions/generate/render).
sub _render_crds {
    my ($self, $crds) = @_;
    my @out;
    for my $crd (@$crds) {
        my $ns       = $self->_namespace_for($crd);
        my $versions = IO::K8s::CRD->served_versions($crd);
        # reuse_core on (D5) - a nested schema shaped like a shipped core
        # class is typed as that class rather than a per-CRD copy.
        my $classes  = IO::K8s::CRD->generate($crd, $ns, reuse_core => 1);
        for my $v (@$versions) {
            my $root = $classes->{ $v->{api_version} } or next;
            my $emitter = IO::K8s::CRD::Emitter->new(
                base => $ns . '::' . ucfirst($v->{name}),
            );
            my $rendered = $emitter->render($root);
            push @out, map { [ $_, $v->{api_version}, $rendered->{$_} ] }
                sort keys %$rendered;
        }
    }
    return \@out;
}

# The base package for one CRD: --namespace when given, otherwise
# IO::K8s::<CamelCase leading DNS label of the group>.
sub _namespace_for {
    my ($self, $crd) = @_;
    return $self->namespace if defined $self->namespace && length $self->namespace;
    my $group = $crd->{spec}{group} // '';
    my ($label) = split /\./, $group;
    $label = 'Crd' unless defined $label && length $label;
    my $camel = join '', map { ucfirst } split /-/, $label;
    return 'IO::K8s::' . $camel;
}

sub _print_files {
    my ($self, $files) = @_;
    my @blocks = @$files;
    for my $i (0 .. $#blocks) {
        my ($path, $api_version, $source) = @{ $blocks[$i] };
        print "\n" if $i;
        print '# ', ('=' x 74), "\n";
        print "# $path  ($api_version)\n";
        print '# ', ('=' x 74), "\n";
        print $source;
    }
    return;
}

sub _write_files {
    my ($self, $files) = @_;
    my $dir = path($self->output_dir);
    for my $block (@$files) {
        my ($path, undef, $source) = @$block;
        my $target = $dir->child($path);
        $target->parent->mkpath;
        $target->spew_utf8($source);
        print STDERR "wrote $target\n";
    }
    return;
}

1;

=seealso

=over

=item * L<kube_crd2class> - The CLI tool built on this class

=item * L<IO::K8s::CRD> - Loads a CRD and generates one class per served version

=item * L<IO::K8s::CRD::Emitter> - Renders those classes as house-style source

=item * L<Kubernetes::REST> - The client whose CRD support this generates classes for

=back

=cut
