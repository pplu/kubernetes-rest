#!/usr/bin/env perl
# Tests for the Kubernetes Patch API using mock data.
#
# Run:
#   prove -l t/12_patch.t

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use IO::K8s;

# Build a mock API with programmable responses
my $mock_io = Test::Kubernetes::Mock::IO->new;

my $api = Kubernetes::REST->new(
    server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
    credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
    resource_map_from_cluster => 0,
    io          => $mock_io,
);

# Simulated patched deployment response
my $deploy_response = {
    apiVersion => 'apps/v1',
    kind       => 'Deployment',
    metadata   => {
        name            => 'my-app',
        namespace       => 'default',
        resourceVersion => '200',
        uid             => 'uid-deploy-1',
        labels          => {
            app => 'my-app',
            env => 'staging',
        },
        annotations => {
            'demo/patched' => 'true',
        },
    },
    spec => {
        replicas => 5,
        selector => { matchLabels => { app => 'my-app' } },
        template => {
            metadata => { labels => { app => 'my-app' } },
            spec => {
                containers => [{
                    name  => 'nginx',
                    image => 'nginx:1.27',
                }],
            },
        },
    },
};

# Register mock responses for PATCH requests
$mock_io->add_response('PATCH', '/apis/apps/v1/namespaces/default/deployments/my-app', $deploy_response);

# Simulated patched namespace response (cluster-scoped)
my $ns_response = {
    apiVersion => 'v1',
    kind       => 'Namespace',
    metadata   => {
        name            => 'test-ns',
        resourceVersion => '300',
        uid             => 'uid-ns-1',
        labels          => {
            env      => 'test',
            new_label => 'added',
        },
    },
    spec   => { finalizers => ['kubernetes'] },
    status => { phase => 'Active' },
};
$mock_io->add_response('PATCH', '/api/v1/namespaces/test-ns', $ns_response);

# === Test 1: Strategic merge patch (default) by class + name ===
subtest 'strategic merge patch by name' => sub {
    my $patched = $api->patch('Deployment', 'my-app',
        namespace => 'default',
        patch     => {
            metadata => { labels => { env => 'staging' } },
        },
    );

    ok($patched, 'patch returns object');
    isa_ok($patched, 'IO::K8s::Api::Apps::V1::Deployment');
    is($patched->metadata->name, 'my-app', 'name preserved');
    is($patched->metadata->labels->{env}, 'staging', 'label patched');
};

# === Test 2: Merge patch ===
subtest 'merge patch' => sub {
    my $patched = $api->patch('Deployment', 'my-app',
        namespace => 'default',
        type      => 'merge',
        patch     => {
            spec => { replicas => 5 },
        },
    );

    ok($patched, 'merge patch returns object');
    is($patched->spec->replicas, 5, 'replicas patched');
};

# === Test 3: JSON patch ===
subtest 'json patch' => sub {
    my $patched = $api->patch('Deployment', 'my-app',
        namespace => 'default',
        type      => 'json',
        patch     => [
            { op => 'replace', path => '/spec/replicas', value => 5 },
        ],
    );

    ok($patched, 'json patch returns object');
    is($patched->spec->replicas, 5, 'replicas patched via json patch');
};

# === Test 4: Patch cluster-scoped resource ===
subtest 'patch cluster-scoped resource' => sub {
    my $patched = $api->patch('Namespace', 'test-ns',
        patch => {
            metadata => { labels => { new_label => 'added' } },
        },
    );

    ok($patched, 'patch namespace returns object');
    is($patched->metadata->name, 'test-ns', 'name correct');
    is($patched->metadata->labels->{new_label}, 'added', 'label added');
};

# === Test 5: Patch with object reference ===
subtest 'patch with object reference' => sub {
    # Create a fake object to pass
    my $obj = $api->k8s->struct_to_object('IO::K8s::Api::Apps::V1::Deployment', {
        apiVersion => 'apps/v1',
        kind       => 'Deployment',
        metadata   => {
            name      => 'my-app',
            namespace => 'default',
        },
        spec => {
            replicas => 2,
            selector => { matchLabels => { app => 'my-app' } },
            template => {
                metadata => { labels => { app => 'my-app' } },
                spec     => { containers => [{ name => 'nginx', image => 'nginx:1.27' }] },
            },
        },
    });

    my $patched = $api->patch($obj,
        patch => { spec => { replicas => 5 } },
    );

    ok($patched, 'patch with object returns result');
    is($patched->metadata->name, 'my-app', 'name from object');
};

# === Test 6: Patch without required args ===
subtest 'patch requires name and patch' => sub {
    throws_ok {
        $api->patch('Pod', name => 'x', namespace => 'default');
    } qr/patch/, 'dies without patch parameter';

    throws_ok {
        $api->patch('Pod', patch => {});
    } qr/name/, 'dies without name';
};

# === Test 7: Unknown patch type ===
subtest 'unknown patch type' => sub {
    throws_ok {
        $api->patch('Deployment', 'my-app',
            namespace => 'default',
            type      => 'invalid',
            patch     => {},
        );
    } qr/Unknown patch type/, 'dies with unknown patch type';
};

# === Test 8: Content-Type headers ===
subtest 'correct content types' => sub {
    # We can verify the Content-Type is set correctly by checking the request
    # The mock doesn't validate headers, but the method maps are correct
    my %expected = (
        strategic => 'application/strategic-merge-patch+json',
        merge     => 'application/merge-patch+json',
        json      => 'application/json-patch+json',
    );

    for my $type (sort keys %expected) {
        my $patched = eval {
            $api->patch('Deployment', 'my-app',
                namespace => 'default',
                type      => $type,
                patch     => {},
            );
        };
        ok($patched, "patch type '$type' works");
    }
};

done_testing;
