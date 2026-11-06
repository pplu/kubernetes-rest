#!/usr/bin/env perl
# karr k77: a caller that hands over the kubeconfig *text* where a path is
# expected (Kubeconfig->new(kubeconfig_path => $yaml), or KUBECONFIG="$(cat
# config)") used to get "Kubeconfig not found: <the whole YAML> and not running
# in-cluster" plus "Unsuccessful stat on filename containing newline". That
# message carries every bearer token and client key of the kubeconfig into logs.
#
# Pinned here: a value that is a document, not a path (it contains a newline,
# carriage return or NUL, or starts - after whitespace - with '{', '[' or
# '---') makes every method that needs the kubeconfig die with
# "kubeconfig expects a path, got a document", naming where the value came from
# (kubeconfig_path or KUBECONFIG) and quoting NOTHING of it. It is checked on the
# raw value before the path_sep split, per entry for an arrayref, so no stat is
# made and no warning is emitted. api() must not fall back to in-cluster for a
# document. Ordinary paths keep their behaviour (regression guards at the end).
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use Path::Tiny qw(path);
use JSON::PP ();

use_ok('Kubernetes::REST::Kubeconfig');

my $tmpdir = tempdir(CLEANUP => 1);

my $TOKEN = 'sekrit-bearer-TOKEN-8f3a91c7';
my $KEY   = 'S0VZREFUQS1ESVNUSU5DVC1QUklWQVRFLUtFWQ==';
my $CERT  = 'Q0VSVERBVEEtRElTVElOQ1QtQ0xJRU5ULUNFUlQ=';

my $yaml = <<"YAML";
apiVersion: v1
kind: Config
current-context: prod
clusters:
- name: prod-cluster
  cluster:
    server: https://203.0.113.7:6443
contexts:
- name: prod
  context:
    cluster: prod-cluster
    user: admin
users:
- name: admin
  user:
    token: $TOKEN
    client-certificate-data: $CERT
    client-key-data: $KEY
YAML

my $data = {
    apiVersion => 'v1', kind => 'Config', 'current-context' => 'prod',
    clusters => [ { name => 'prod-cluster', cluster => { server => 'https://203.0.113.7:6443' } } ],
    contexts => [ { name => 'prod', context => { cluster => 'prod-cluster', user => 'admin' } } ],
    users    => [ { name => 'admin', user => {
        token => $TOKEN, 'client-certificate-data' => $CERT, 'client-key-data' => $KEY } } ],
};
my $json = JSON::PP->new->canonical->encode($data);    # single line, no newline
my $flow = "--- $json";                                  # JSON is YAML flow style

# A genuine kubeconfig file, for the arrayref case and the regression guards.
my $real = "$tmpdir/real-config";
path($real)->spew_raw(<<'YAML');
apiVersion: v1
kind: Config
current-context: dev
clusters:
- name: dev-cluster
  cluster:
    server: https://198.51.100.1:6443
contexts:
- name: dev
  context:
    cluster: dev-cluster
    user: dev-user
users:
- name: dev-user
  user:
    token: dev-token
YAML

# Run $code, collect warnings, return ($error, \@warnings).
sub run_caught {
    my ($code) = @_;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $ok = eval { $code->(); 1 };
    my $err = $ok ? undef : "$@";
    return ($err, \@warnings);
}

# The whole contract in one assertion: it dies, with the document message, naming
# the source, quoting nothing of the document, and without a single warning.
sub document_rejected {
    my ($code, $doc, $source, $label) = @_;
    my ($err, $warnings) = run_caught($code);
    subtest $label => sub {
        ok(defined $err, 'dies') or return;
        like($err, qr/kubeconfig expects a path, got a document/, 'says a document was given');
        like($err, qr/\b\Q$source\E\b/, "names the source ($source)");
        unlike($err, qr/kubeconfig_path/, 'does not name kubeconfig_path as the source')
            if $source eq 'KUBECONFIG';
        unlike($err, qr/\Q$_\E/, "message does not leak $_")
            for $TOKEN, $KEY, $CERT, 'apiVersion', '203.0.113.7';
        for my $line (grep { length } split /\r?\n/, $doc) {
            unlike($err, qr/\Q$line\E/, "message does not quote the document line '$line'")
                if length($line) >= 6 and $line !~ /^\s*$/;
        }
        is(scalar @$warnings, 0, 'no warning at all') or diag explain $warnings;
        unlike(join('', @$warnings), qr/Unsuccessful stat/, 'no stat on the document');
    };
}

my %documents = (
    'multi-line YAML'            => $yaml,
    'single-line JSON'           => $json,
    'one-line --- flow document' => $flow,
);

# Every document shape, through every method that needs the kubeconfig.
for my $name (sort keys %documents) {
    my $doc = $documents{$name};
    for my $method (qw(api kubeconfig_paths contexts current_context_name)) {
        document_rejected(
            sub { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $doc)->$method },
            $doc, 'kubeconfig_path', "$name as kubeconfig_path: $method");
    }
}

# Leading whitespace does not hide a document.
document_rejected(
    sub { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => "   $json")->api },
    $json, 'kubeconfig_path', 'JSON with leading whitespace is still a document');

# NUL and CR alone mark a document too.
{
    my $nul = "/a/path\0$TOKEN";
    document_rejected(
        sub { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $nul)->kubeconfig_paths },
        $nul, 'kubeconfig_path', 'NUL byte marks a document');
    my $cr = "/a/path\r$TOKEN";
    document_rejected(
        sub { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $cr)->kubeconfig_paths },
        $cr, 'kubeconfig_path', 'CR marks a document');
}

# A document inside a list is a caller mistake, not a missing file to skip.
for my $method (qw(kubeconfig_paths api contexts)) {
    document_rejected(
        sub { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => [ $real, $yaml ])->$method },
        $yaml, 'kubeconfig_path', "arrayref with a document as second entry: $method");
}

# The same document arriving through KUBECONFIG names KUBECONFIG.
for my $method (qw(kubeconfig_paths api contexts current_context_name)) {
    document_rejected(
        sub {
            local $ENV{KUBECONFIG} = $yaml;
            Kubernetes::REST::Kubeconfig->new->$method;
        },
        $yaml, 'KUBECONFIG', "KUBECONFIG holding a document: $method");
}

# An in-cluster service account must not rescue a document.
{
    path("$tmpdir/token")->spew_raw("sa-token\n");
    path("$tmpdir/ca.crt")->spew_raw("FAKECA\n");
    no warnings 'once';
    local $Kubernetes::REST::Kubeconfig::SA_TOKEN = "$tmpdir/token";
    local $Kubernetes::REST::Kubeconfig::SA_CA    = "$tmpdir/ca.crt";
    local $ENV{KUBERNETES_SERVICE_HOST} = '10.96.0.1';
    local $ENV{KUBERNETES_SERVICE_PORT} = '443';

    document_rejected(
        sub { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $yaml)->api },
        $yaml, 'kubeconfig_path', 'service account token present: api() still dies for a document');
    document_rejected(
        sub {
            local $ENV{KUBECONFIG} = $yaml;
            Kubernetes::REST::Kubeconfig->new->api;
        },
        $yaml, 'KUBECONFIG', 'service account token present: api() still dies for a KUBECONFIG document');

    # Guard: the fallback itself still works for a path that does not exist.
    my $api = eval { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => "$tmpdir/absent")->api };
    ok($api, 'a missing file still falls back to the in-cluster client');
}

# Regression guards: ordinary values behave as before.
{
    my ($err, $warnings) = run_caught(sub {
        Kubernetes::REST::Kubeconfig->new(kubeconfig_path => "$tmpdir/no such dir/config")->contexts;
    });
    like($err, qr/Kubeconfig not found: \Q$tmpdir\E\/no such dir\/config/,
        'missing path with a space is named in "Kubeconfig not found"');
    unlike($err, qr/got a document/, 'a path with a space is not mistaken for a document');
    is(scalar @$warnings, 0, 'no warning for a missing path with a space');

    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $real);
    is_deeply($kc->kubeconfig_paths, [$real], 'an existing path is kept as the one entry');
    is_deeply($kc->contexts, ['dev'], 'an existing kubeconfig is read normally');
    is($kc->current_context_name, 'dev', 'its current-context is read');

    my $list = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => [ "$tmpdir/absent", $real ]);
    is_deeply($list->contexts, ['dev'], 'an arrayref of paths still skips a missing file');
}

# A document hiding in a path list: the leading-marker check also applies to
# every entry after the path_sep split, so "path:{...json...}" cannot get its
# JSON pieces stat'ed and quoted in "Kubeconfig not found".
for my $prefix ("$tmpdir/absent", $real) {
    my $list = "$prefix:$json";
    for my $method (qw(kubeconfig_paths api contexts)) {
        document_rejected(
            sub { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $list)->$method },
            $json, 'kubeconfig_path', "path list '" . ($prefix eq $real ? 'real' : 'missing') . ":JSON' as kubeconfig_path: $method");
        document_rejected(
            sub {
                local $ENV{KUBECONFIG} = $list;
                Kubernetes::REST::Kubeconfig->new->$method;
            },
            $json, 'KUBECONFIG', "path list '" . ($prefix eq $real ? 'real' : 'missing') . ":JSON' via KUBECONFIG: $method");
    }
}

# The croak names the caller's line, not a line inside Kubeconfig.pm - also when
# the kubeconfig is needed through a lazy builder (api, contexts,
# current_context_name reach kubeconfig_paths that way).
for my $method (qw(kubeconfig_paths api contexts current_context_name)) {
    my ($err, $line);
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $yaml);
    { local $SIG{__WARN__} = sub { }; $line = __LINE__; eval { $kc->$method; 1 } or $err = "$@"; }
    like($err, qr/got a document/, "$method: dies with the document message");
    like($err, qr/ at \Q@{[__FILE__]}\E line $line\.\n\z/, "$method: at the caller's line");
    is(scalar(() = ($err // '') =~ / at \S+ line \d+\./g), 1, "$method: with one location");
}
{
    my ($err, $line);
    local $ENV{KUBECONFIG} = $yaml;
    my $kc = Kubernetes::REST::Kubeconfig->new;
    $line = __LINE__; eval { $kc->api; 1 } or $err = "$@";
    like($err, qr/ at \Q@{[__FILE__]}\E line $line\.\n\z/, 'api via KUBECONFIG: at the caller\'s line');
}

done_testing;
