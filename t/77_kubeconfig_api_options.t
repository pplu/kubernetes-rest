#!/usr/bin/env perl
# karr k80: Kubeconfig->api takes more than a context name. api($context,
# %options) passes %options on to Kubernetes::REST->new, next to the server and
# credentials it builds from the kubeconfig - on the kubeconfig path and on the
# in-cluster fallback alike.
#
# The point: a caller that switches discovery off (resource_map_from_cluster =>
# 0) must not see "Falling back to the built-in resource map: ..." on STDERR
# when discovery would fail, next to its own clean error. With no way to hand
# options through, the only client api() could return had discovery on.
# server and credentials are not options here (api() builds them from the
# kubeconfig); passing one croaks naming the key and never the value.
#
# No request leaves the process: every call that sends one first checks that
# the client's io is the mock handed in, and is skipped otherwise.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use Path::Tiny qw(path);
use Scalar::Util qw(refaddr);

use Test::Kubernetes::Mock ();
use Kubernetes::REST::Kubeconfig;

my $tmpdir = tempdir(CLEANUP => 1);

# A mock whose discovery documents are an error status, recording the path of
# every request it is asked for.
{
    package Test::K80::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has paths => (is => 'ro', default => sub { [] });

    around call => sub {
        my ($orig, $self, $req, @rest) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        $path =~ s{\?.*}{};
        push @{ $self->paths }, $path;
        return Test::Kubernetes::Mock::Response->new(
            status  => 503,
            content => '{"kind":"Status","status":"Failure","message":"discovery unavailable"}',
        ) if $path eq '/api' or $path eq '/apis';
        return $self->$orig($req, @rest);
    };
}

sub mock_io {
    my $io = Test::K80::IO->new;
    $io->add_response('GET', '/version', { major => '1', minor => '30', gitVersion => 'v1.30.0' });
    $io->add_response('GET', '/api/v1/namespaces/default/pods', {
        apiVersion => 'v1', kind => 'PodList',
        items => [ { apiVersion => 'v1', kind => 'Pod', metadata => { name => 'web', namespace => 'default' } } ],
    });
    return $io;
}

my $kubeconfig = "$tmpdir/config";
path($kubeconfig)->spew_raw(<<'YAML');
apiVersion: v1
kind: Config
current-context: main
clusters:
- name: main-cluster
  cluster:
    server: https://kube.invalid:6443
- name: other-cluster
  cluster:
    server: https://other.invalid:6443
contexts:
- name: main
  context: { cluster: main-cluster, user: main-user }
- name: other
  context: { cluster: other-cluster, user: other-user }
users:
- name: main-user
  user: { token: main-token }
- name: other-user
  user: { token: other-token }
YAML

sub kc { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $kubeconfig) }

# Whatever $code writes to the process's STDERR, captured at the file
# descriptor, so a plain warn, a carp and a die handler all land in it.
sub stderr_of {
    my ($code) = @_;
    my $file = "$tmpdir/stderr." . int(rand 1e9);
    open my $saved, '>&', \*STDERR or die "dup STDERR: $!";
    open STDERR, '>', $file or die "redirect STDERR: $!";
    my $ok = eval { $code->(); 1 };
    my $err = $@;
    close STDERR;
    open STDERR, '>&', $saved or die "restore STDERR: $!";
    die $err unless $ok;
    return path($file)->slurp_raw;
}

sub is_mock { my ($api, $io) = @_; return refaddr($api->io) == refaddr($io) }

subtest 'options reach the client, server and credentials still come from the kubeconfig' => sub {
    for my $case (['current context', undef, 'https://kube.invalid:6443', 'main-token'],
                  ['named context', 'other', 'https://other.invalid:6443', 'other-token']) {
        my ($label, $ctx, $endpoint, $token) = @$case;
        my $io = mock_io();
        my $api = eval { kc()->api($ctx, resource_map_from_cluster => 0, io => $io) };
        ok($api, "$label: api() returns a client") or diag $@;
        $api or next;
        is($api->resource_map_from_cluster, 0, "$label: resource_map_from_cluster is 0");
        ok(is_mock($api, $io), "$label: io is exactly the one passed");
        is($api->server->endpoint, $endpoint, "$label: endpoint from the kubeconfig");
        is($api->credentials->token, $token, "$label: token from the kubeconfig");
    }
};

subtest 'discovery off writes nothing to STDERR when discovery would fail' => sub {
    my $call = sub {
        my $api = shift;
        my $pods = $api->list('Pod', namespace => 'default');
        return $pods;
    };

    # Control: discovery on, same call - the fallback warning must show, which
    # proves the capture sees it.
    my $io_on = mock_io();
    my $api_on = kc()->api(undef, io => $io_on);
    ok(is_mock($api_on, $io_on), 'control: io is the mock') or return;
    my $err_on = stderr_of(sub { $call->($api_on) });
    like($err_on, qr/Falling back to the built-in resource map/, 'control: discovery on writes the fallback warning');
    ok((grep { $_ eq '/api' } @{ $io_on->paths }), 'control: /api was requested');

    # Off: same call, nothing on STDERR, no discovery request.
    my $io_off = mock_io();
    my $api_off = kc()->api(undef, io => $io_off, resource_map_from_cluster => 0);
    ok(is_mock($api_off, $io_off), 'off: io is the mock') or return;
    my $got;
    my $err_off = stderr_of(sub { $got = $call->($api_off) });
    is($err_off, '', 'off: nothing written to STDERR');
    is(scalar @{ $got->items }, 1, 'off: the list still answered');
    is_deeply([ grep { $_ eq '/api' or $_ eq '/apis' } @{ $io_off->paths } ], [],
        'off: no request to /api or /apis');
};

subtest 'in-cluster fallback carries the options too' => sub {
    path("$tmpdir/token")->spew_raw("sa-token\n");
    path("$tmpdir/ca.crt")->spew_raw("FAKECA\n");
    no warnings 'once';
    local $Kubernetes::REST::Kubeconfig::SA_TOKEN = "$tmpdir/token";
    local $Kubernetes::REST::Kubeconfig::SA_CA    = "$tmpdir/ca.crt";
    local $ENV{KUBERNETES_SERVICE_HOST} = '10.96.0.1';
    local $ENV{KUBERNETES_SERVICE_PORT} = '443';

    my $io = mock_io();
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => "$tmpdir/absent");
    my $api = eval { $kc->api(undef, resource_map_from_cluster => 0, io => $io) };
    ok($api, 'api() falls back to in-cluster') or diag $@;
    $api or return;
    is($api->server->endpoint, 'https://10.96.0.1:443', 'it is the in-cluster client');
    is($api->resource_map_from_cluster, 0, 'resource_map_from_cluster is 0');
    ok(is_mock($api, $io), 'io is exactly the one passed');
};

subtest 'server and credentials are not options' => sub {
    my $value = 'sekrit-opt-token';
    for my $case (['server', server => { endpoint => "https://$value.invalid" }],
                  ['credentials', credentials => { token => $value }]) {
        my ($key, @opts) = @$case;
        my $api = eval { kc()->api(undef, @opts) };
        my $err = $@;
        ok(!$api, "$key: api() does not return a client") or next;
        like($err, qr/\b\Q$key\E\b/, "$key: the message names the key");
        like($err, qr/kubeconfig/, "$key: and says api() builds it from the kubeconfig");
        unlike($err, qr/\Q$value\E/, "$key: the message does not contain the value");
    }
};

subtest 'an odd option list croaks' => sub {
    my $api = eval { kc()->api(undef, 'resource_map_from_cluster') };
    my $err = $@;
    ok(!$api, 'api() does not return a client');
    like($err, qr/\S/, 'with a message');
};

subtest 'without options api() behaves as before' => sub {
    for my $case (['no arguments', undef, 'https://kube.invalid:6443'],
                  ['a context name', 'other', 'https://other.invalid:6443']) {
        my ($label, $ctx, $endpoint) = @$case;
        my $api = defined $ctx ? kc()->api($ctx) : kc()->api;
        is($api->resource_map_from_cluster, 1, "$label: discovery stays on");
        isa_ok($api->io, 'Kubernetes::REST::LWPIO', "$label: io");
        is($api->server->endpoint, $endpoint, "$label: endpoint from the kubeconfig");
    }
};

done_testing;
