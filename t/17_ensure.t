#!/usr/bin/env perl
# Tests for ensure / ensure_all idempotent apply

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api);

my $api = mock_api();
my $io  = $api->io;
my $k8s = $api->k8s;

sub add {
    my ($method, $path, $data) = @_;
    $io->add_response($method, $path, $data);
}

sub ns_obj {
    my ($name) = @_;
    return $k8s->new_object('Namespace', metadata => { name => $name });
}

# Case 1: resource does not exist — ensure creates it.
{
    # The mock returns 404 by default for unknown GETs; register a POST mock.
    add('POST', '/api/v1/namespaces', {
        apiVersion => 'v1',
        kind       => 'Namespace',
        metadata   => { name => 'new-ns', resourceVersion => '1' },
    });

    my $obj = ns_obj('new-ns');
    my $result = $api->ensure($obj);
    isa_ok($result, 'IO::K8s::Api::Core::V1::Namespace', 'create path: typed result');
    is($result->metadata->name, 'new-ns', 'create path: name matches');
    is($result->metadata->resourceVersion, '1', 'create path: resourceVersion present');
}

# Case 2: resource exists — ensure updates it and preserves resourceVersion.
{
    add('GET', '/api/v1/namespaces/existing-ns', {
        apiVersion => 'v1',
        kind       => 'Namespace',
        metadata   => { name => 'existing-ns', resourceVersion => '42' },
    });
    add('PUT', '/api/v1/namespaces/existing-ns', {
        apiVersion => 'v1',
        kind       => 'Namespace',
        metadata   => { name => 'existing-ns', resourceVersion => '43' },
    });

    my $obj = ns_obj('existing-ns');
    my $result = $api->ensure($obj);
    is($result->metadata->name, 'existing-ns', 'update path: name matches');
    is($result->metadata->resourceVersion, '43', 'update path: new resourceVersion');
    is($obj->metadata->resourceVersion, '42', 'update path: rv copied from existing before PUT');
}

# Case 3: ensure_all applies each object.
{
    add('POST', '/api/v1/namespaces', {
        apiVersion => 'v1',
        kind       => 'Namespace',
        metadata   => { name => 'batch-a' },
    });

    my @results = $api->ensure_all(ns_obj('batch-a'));
    is(scalar @results, 1, 'ensure_all returns one result per input');
    is($results[0]->metadata->name, 'batch-a', 'ensure_all preserves order');
}

# Case 4: PVC is immutable — existing PVC returned unchanged, no PUT attempted.
{
    add('GET', '/api/v1/namespaces/default/persistentvolumeclaims/data', {
        apiVersion => 'v1',
        kind       => 'PersistentVolumeClaim',
        metadata   => { name => 'data', namespace => 'default', resourceVersion => '7' },
        spec       => { accessModes => ['ReadWriteOnce'] },
    });
    # Deliberately no PUT mock — ensure must not attempt one.

    my $pvc = $k8s->new_object('PersistentVolumeClaim',
        metadata => { name => 'data', namespace => 'default' },
    );
    my $result = eval { $api->ensure($pvc) };
    ok(!$@, 'ensure on existing PVC does not die') or diag $@;
    is($result && $result->metadata->name, 'data', 'PVC: returns existing object');
}

# Case 5: hashref input — inflated via struct_to_object, then create.
{
    add('POST', '/api/v1/namespaces/default/secrets', {
        apiVersion => 'v1',
        kind       => 'Secret',
        metadata   => { name => 'my-secret', namespace => 'default', resourceVersion => '1' },
    });

    my $result = $api->ensure({
        apiVersion => 'v1',
        kind       => 'Secret',
        metadata   => { name => 'my-secret', namespace => 'default' },
        stringData => { password => 'hunter2' },
    });
    isa_ok($result, 'IO::K8s::Api::Core::V1::Secret', 'hashref path: typed result');
    is($result->metadata->name, 'my-secret', 'hashref path: name matches');
}

# karr k34: a hashref manifest resolves through its apiVersion. The bare Kind
# HorizontalPodAutoscaler maps to autoscaling/v2; an autoscaling/v1 manifest
# must stay v1 - class, endpoint and the apiVersion in the request body.
my $HPA_V1 = '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers';
my $HPA_V2 = '/apis/autoscaling/v2/namespaces/default/horizontalpodautoscalers';

sub hpa_manifest {
    my ($name, %extra) = @_;
    return {
        kind     => 'HorizontalPodAutoscaler',
        metadata => { name => $name, namespace => 'default' },
        spec     => {
            scaleTargetRef => { apiVersion => 'apps/v1', kind => 'Deployment', name => 'web' },
            maxReplicas    => 3,
        },
        %extra,
    };
}

sub requests_since {
    my ($mark) = @_;
    my @requests = @{ $io->requests };
    return @requests[ $mark .. $#requests ];
}

# Case 6: apiVersion autoscaling/v1 - v1 class, v1 endpoint, v1 body.
{
    add('POST', $HPA_V1, {
        %{ hpa_manifest('hpa-v1', apiVersion => 'autoscaling/v1') },
        metadata => { name => 'hpa-v1', namespace => 'default', resourceVersion => '1' },
    });

    my $mark = @{ $io->requests };
    my $result = eval { $api->ensure(hpa_manifest('hpa-v1', apiVersion => 'autoscaling/v1')) };
    is($@, '', 'apiVersion hashref: ensure does not die');
    isa_ok($result, 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
        'apiVersion hashref: result');

    my ($post) = grep { $_->{method} eq 'POST' } requests_since($mark);
    is($post && $post->{path}, $HPA_V1,
        'apiVersion hashref: created on the autoscaling/v1 endpoint');
    like($post && $post->{content}, qr{"apiVersion":"autoscaling/v1"},
        'apiVersion hashref: the body still says autoscaling/v1');
}

# Case 7: no apiVersion - the bare Kind resolves as before (its default, v2).
{
    add('POST', $HPA_V2, {
        %{ hpa_manifest('hpa-bare', apiVersion => 'autoscaling/v2') },
        metadata => { name => 'hpa-bare', namespace => 'default', resourceVersion => '1' },
    });

    my $mark = @{ $io->requests };
    my $result = eval { $api->ensure(hpa_manifest('hpa-bare')) };
    is($@, '', 'bare-Kind hashref: ensure does not die');
    isa_ok($result, 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscaler',
        'bare-Kind hashref: result');
    my ($post) = grep { $_->{method} eq 'POST' } requests_since($mark);
    is($post && $post->{path}, $HPA_V2,
        'bare-Kind hashref: created on the default (v2) endpoint');
}

# Case 8: an apiVersion no class serves croaks - no silent fallback to the
# bare Kind's default version, and nothing is sent.
{
    my $mark = @{ $io->requests };
    eval { $api->ensure(hpa_manifest('hpa-v9', apiVersion => 'autoscaling/v9')) };
    like($@, qr{autoscaling/v9}, 'unknown apiVersion: the error names the apiVersion');
    like($@, qr{HorizontalPodAutoscaler}, 'unknown apiVersion: the error names the Kind');
    is(scalar(my @sent = requests_since($mark)), 0, 'unknown apiVersion: no request sent');
}

done_testing;
