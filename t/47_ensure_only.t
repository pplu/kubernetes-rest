#!/usr/bin/env perl
# ensure_only prunes: everything labelled in the given kinds/namespaces that is
# not in the object set gets deleted. These tests pin what is NOT deleted as
# much as what is - a key mismatch between the applied objects and the listed
# items deletes the objects that were just applied.
#
# karr k33: the Kind of a listed item used to come from the `kinds` string, the
# Kind of an expected object from its class. A qualified
# 'group/version/Kind' entry never matched, so the applied objects went too.
# karr k34: a hashref manifest resolves through its apiVersion, not through the
# bare Kind's default version.
# karr k39: the key carries the API group - the same Kind name in two groups
# is two resources - but still no version.

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

my $HPA_V1 = '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers';
my $HPA_V2 = '/apis/autoscaling/v2/namespaces/default/horizontalpodautoscalers';

# The mock matches on the path including its query string, and ensure_only
# always lists with a labelSelector.
my $SEL = q{?labelSelector=app=demo};

sub requests_for {
    my ($io, $method) = @_;
    return [ map { $_->{path} } grep { $_->{method} eq $method } @{ $io->requests } ];
}

sub hpa_item {
    my ($name) = @_;
    return {
        metadata => {
            name      => $name,
            namespace => 'default',
            labels    => { app => 'demo' },
        },
        spec => {
            scaleTargetRef => { apiVersion => 'apps/v1', kind => 'Deployment', name => 'web' },
            maxReplicas    => 3,
        },
    };
}

sub hpa_v1_manifest {
    my ($name) = @_;
    return {
        apiVersion => 'autoscaling/v1',
        kind       => 'HorizontalPodAutoscaler',
        %{ hpa_item($name) },
    };
}

# The server side of one HPA create plus a label-selected list of two items,
# the applied 'keep-me' and a leftover 'stale'. Items carry no kind/apiVersion,
# as in a real list response.
sub mock_hpa_cluster {
    my ($io, $list_path, $list_version) = @_;
    $io->add_response('POST', $HPA_V1, {
        %{ hpa_v1_manifest('keep-me') },
        metadata => { %{ hpa_item('keep-me')->{metadata} }, resourceVersion => '1' },
    });
    $io->add_response('GET', $list_path . $SEL, {
        apiVersion => $list_version,
        kind       => 'HorizontalPodAutoscalerList',
        items      => [ hpa_item('keep-me'), hpa_item('stale') ],
    });
    $io->add_response('DELETE', "$list_path/stale",
        { kind => 'Status', apiVersion => 'v1', status => 'Success' });
}

subtest 'k33: a qualified kinds entry keeps the objects it just applied' => sub {
    my $api = mock_api();
    my $io  = $api->io;
    mock_hpa_cluster($io, $HPA_V1, 'autoscaling/v1');

    my $hpa = $api->k8s->new_object(
        'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler', hpa_item('keep-me'));

    my @applied = eval {
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [$hpa],
            kinds      => ['autoscaling/v1/HorizontalPodAutoscaler'],
            namespaces => ['default'],
        );
    };
    is($@, '', 'ensure_only does not die');
    is(scalar @applied, 1, 'one applied object returned');

    is_deeply(requests_for($io, 'GET'),
        [ "$HPA_V1/keep-me", $HPA_V1 ],
        'the qualified entry lists the autoscaling/v1 collection');
    is_deeply(requests_for($io, 'DELETE'), [ "$HPA_V1/stale" ],
        'only the unexpected item is deleted, never the applied keep-me');
};

subtest 'bare kinds entry: unchanged - the unexpected item goes, the expected stays' => sub {
    my $api = mock_api();
    my $io  = $api->io;
    my $CM  = '/api/v1/namespaces/default/configmaps';
    my $cm_item = sub {
        my ($name) = @_;
        return { metadata => { name => $name, namespace => 'default', labels => { app => 'demo' } } };
    };
    $io->add_response('POST', $CM, {
        apiVersion => 'v1', kind => 'ConfigMap',
        metadata   => { %{ $cm_item->('keep-me')->{metadata} }, resourceVersion => '1' },
    });
    $io->add_response('GET', $CM . $SEL, {
        apiVersion => 'v1', kind => 'ConfigMapList',
        items      => [ $cm_item->('keep-me'), $cm_item->('stale') ],
    });
    $io->add_response('DELETE', "$CM/stale",
        { kind => 'Status', apiVersion => 'v1', status => 'Success' });

    $api->ensure_only(
        label      => 'app=demo',
        objects    => [ $api->k8s->new_object('ConfigMap', $cm_item->('keep-me')) ],
        kinds      => ['ConfigMap'],
        namespaces => ['default'],
    );

    is_deeply(requests_for($io, 'DELETE'), [ "$CM/stale" ],
        'bare Kind: stale deleted, keep-me kept');
};

subtest 'the key is the Kind, not the version: a v1 object survives a bare (v2) listing' => sub {
    # Bare HorizontalPodAutoscaler resolves to autoscaling/v2, the object was
    # applied as autoscaling/v1. Same resource in two representations - keying
    # on the full class name instead of the Kind would delete keep-me here.
    my $api = mock_api();
    my $io  = $api->io;
    mock_hpa_cluster($io, $HPA_V2, 'autoscaling/v2');

    $api->ensure_only(
        label      => 'app=demo',
        objects    => [ $api->k8s->new_object(
            'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler', hpa_item('keep-me')) ],
        kinds      => ['HorizontalPodAutoscaler'],
        namespaces => ['default'],
    );

    is_deeply(requests_for($io, 'DELETE'), [ "$HPA_V2/stale" ],
        'keep-me listed through v2 is still recognised');
};

subtest 'k34: a hashref in objects resolves through its apiVersion' => sub {
    my $api = mock_api();
    my $io  = $api->io;
    mock_hpa_cluster($io, $HPA_V1, 'autoscaling/v1');

    my @applied = eval {
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [ hpa_v1_manifest('keep-me') ],
            kinds      => ['autoscaling/v1/HorizontalPodAutoscaler'],
            namespaces => ['default'],
        );
    };
    is($@, '', 'ensure_only does not die');
    isa_ok($applied[0], 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
        'applied object');
    is_deeply(requests_for($io, 'POST'), [ $HPA_V1 ],
        'created on the autoscaling/v1 endpoint, not the v2 default');
    is_deeply(requests_for($io, 'DELETE'), [ "$HPA_V1/stale" ],
        'the applied manifest is recognised in the listing');
};

subtest 'k34: an apiVersion no class serves croaks before anything is applied' => sub {
    my $api = mock_api();
    my $io  = $api->io;

    my $manifest = hpa_v1_manifest('keep-me');
    $manifest->{apiVersion} = 'autoscaling/v9';

    eval {
        $api->ensure_only(
            label   => 'app=demo',
            objects => [ $api->k8s->new_object('ConfigMap',
                metadata => { name => 'first', namespace => 'default' }), $manifest ],
            kinds   => ['HorizontalPodAutoscaler'],
        );
    };
    like($@, qr{autoscaling/v9}, 'the error names the apiVersion');
    like($@, qr{HorizontalPodAutoscaler}, 'the error names the Kind');
    is_deeply($io->requests, [], 'no request was sent - not even for the valid object');
};

# ---------------------------------------------------------------------------
# Unstructured items: their Kind is instance data, the class name is just
# 'Unstructured'. Keying on the class name would make every Unstructured Kind
# collide - a stale Gadget named like an applied Widget would survive.
# ---------------------------------------------------------------------------
my %CORE_DISCOVERY = (
    kind       => 'APIGroupDiscoveryList',
    apiVersion => 'apidiscovery.k8s.io/v2',
    items      => [
        {
            metadata => { name => '' },
            versions => [
                {
                    version   => 'v1',
                    resources => [
                        {
                            resource     => 'pods',
                            responseKind => { group => '', version => 'v1', kind => 'Pod' },
                            scope        => 'Namespaced',
                        },
                    ],
                },
            ],
        },
    ],
);

my %GROUPED_DISCOVERY = (
    kind  => 'APIGroupDiscoveryList',
    items => [
        {
            metadata => { name => 'example.com' },
            versions => [
                {
                    version   => 'v1',
                    resources => [
                        {
                            resource     => 'widgets',
                            responseKind => { group => 'example.com', version => 'v1', kind => 'Widget' },
                            scope        => 'Namespaced',
                        },
                        {
                            resource     => 'gadgets',
                            responseKind => { group => 'example.com', version => 'v1', kind => 'Gadget' },
                            scope        => 'Namespaced',
                        },
                    ],
                },
            ],
        },
    ],
);

subtest 'Unstructured: the key uses the item Kind, not the class name' => sub {
    my $io = Test::Kubernetes::Mock::IO->new;
    $io->add_response('GET', '/api',  \%CORE_DISCOVERY);
    $io->add_response('GET', '/apis', \%GROUPED_DISCOVERY);
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
    );

    my $WIDGETS = '/apis/example.com/v1/namespaces/default/widgets';
    my $GADGETS = '/apis/example.com/v1/namespaces/default/gadgets';
    my $item = sub {
        my ($kind, $name) = @_;
        return {
            apiVersion => 'example.com/v1',
            kind       => $kind,
            metadata   => { name => $name, namespace => 'default', labels => { app => 'demo' } },
        };
    };

    $io->add_response('POST', $WIDGETS, $item->('Widget', 'foo'));
    $io->add_response('GET', $WIDGETS . $SEL, {
        apiVersion => 'example.com/v1', kind => 'WidgetList',
        items      => [ $item->('Widget', 'foo'), $item->('Widget', 'stale') ],
    });
    $io->add_response('GET', $GADGETS . $SEL, {
        apiVersion => 'example.com/v1', kind => 'GadgetList',
        items      => [ $item->('Gadget', 'foo') ],
    });
    my $ok = { kind => 'Status', apiVersion => 'v1', status => 'Success' };
    $io->add_response('DELETE', "$WIDGETS/stale", $ok);
    $io->add_response('DELETE', "$GADGETS/foo", $ok);

    my @applied = eval {
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [ $item->('Widget', 'foo') ],
            kinds      => [qw( Widget Gadget )],
            namespaces => ['default'],
        );
    };
    is($@, '', 'ensure_only does not die');
    isa_ok($applied[0], 'IO::K8s::Unstructured', 'applied object');

    is_deeply([ sort @{ requests_for($io, 'DELETE') } ],
        [ "$GADGETS/foo", "$WIDGETS/stale" ],
        'the applied Widget foo stays; the stale Widget and the same-named Gadget go');
};

# ---------------------------------------------------------------------------
# karr k39: Istio's Gateway (networking.istio.io) and the Gateway API's
# Gateway (gateway.networking.k8s.io) share a Kind name. With the same
# namespace and name they are still two resources: a labelled one that is not
# in the object set must go, whichever group the applied one is in.
# ---------------------------------------------------------------------------
my $ISTIO_GW = '/apis/networking.istio.io/v1/namespaces/default/gateways';
my $API_GW   = '/apis/gateway.networking.k8s.io/v1/namespaces/default/gateways';

sub gateway_item {
    my ($name) = @_;
    return {
        metadata => { name => $name, namespace => 'default', labels => { app => 'demo' } },
        spec     => { selector => 'ingress' },
    };
}

subtest 'k39: the same Kind in another group is another resource' => sub {
    my $api = mock_api();
    my $io  = $api->io;
    my $ok  = { kind => 'Status', apiVersion => 'v1', status => 'Success' };

    $io->add_response('POST', $API_GW, {
        apiVersion => 'gateway.networking.k8s.io/v1', kind => 'Gateway',
        %{ gateway_item('web') },
    });
    # Items carry no kind/apiVersion, as in a real list response - the group
    # comes from the class each collection was listed through.
    $io->add_response('GET', $API_GW . $SEL, {
        apiVersion => 'gateway.networking.k8s.io/v1', kind => 'GatewayList',
        items      => [ gateway_item('web') ],
    });
    $io->add_response('GET', $ISTIO_GW . $SEL, {
        apiVersion => 'networking.istio.io/v1', kind => 'GatewayList',
        items      => [ gateway_item('web') ],
    });
    $io->add_response('DELETE', "$API_GW/web",   $ok);
    $io->add_response('DELETE', "$ISTIO_GW/web", $ok);

    my @applied = eval {
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [ $api->k8s->new_object('+My::GatewayApi::Gateway', gateway_item('web')) ],
            kinds      => [qw( +My::GatewayApi::Gateway +My::Istio::Gateway )],
            namespaces => ['default'],
        );
    };
    is($@, '', 'ensure_only does not die');
    is(scalar @applied, 1, 'one applied object returned');

    is_deeply(requests_for($io, 'GET'),
        [ "$API_GW/web", $API_GW, $ISTIO_GW ],
        'both groups were listed');
    is_deeply(requests_for($io, 'DELETE'), [ "$ISTIO_GW/web" ],
        'the Istio Gateway web goes; the applied Gateway API Gateway web stays');
};

subtest 'k39: an Unstructured item keys on the group in its own apiVersion' => sub {
    # The applied object is a typed Istio Gateway; the bare 'Gateway' entry
    # resolves through discovery to Unstructured in another group, whose item
    # carries its group in its apiVersion. Same Kind, namespace and name -
    # different resource.
    my $io = Test::Kubernetes::Mock::IO->new;
    $io->add_response('GET', '/api', \%CORE_DISCOVERY);
    $io->add_response('GET', '/apis', {
        kind  => 'APIGroupDiscoveryList',
        items => [ {
            metadata => { name => 'gateway.example.com' },
            versions => [ {
                version   => 'v1',
                resources => [ {
                    resource     => 'gateways',
                    responseKind => { group => 'gateway.example.com', version => 'v1', kind => 'Gateway' },
                    scope        => 'Namespaced',
                } ],
            } ],
        } ],
    });
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
    );

    my $OTHER_GW = '/apis/gateway.example.com/v1/namespaces/default/gateways';
    $io->add_response('POST', $ISTIO_GW, {
        apiVersion => 'networking.istio.io/v1', kind => 'Gateway',
        %{ gateway_item('web') },
    });
    $io->add_response('GET', $OTHER_GW . $SEL, {
        apiVersion => 'gateway.example.com/v1', kind => 'GatewayList',
        items      => [ {
            apiVersion => 'gateway.example.com/v1', kind => 'Gateway',
            %{ gateway_item('web') },
        } ],
    });
    $io->add_response('DELETE', "$OTHER_GW/web",
        { kind => 'Status', apiVersion => 'v1', status => 'Success' });

    eval {
        $api->ensure_only(
            label      => 'app=demo',
            objects    => [ $api->k8s->new_object('+My::Istio::Gateway', gateway_item('web')) ],
            kinds      => ['Gateway'],
            namespaces => ['default'],
        );
    };
    is($@, '', 'ensure_only does not die');
    is_deeply(requests_for($io, 'POST'), [ $ISTIO_GW ], 'the Istio Gateway was applied');
    is_deeply(requests_for($io, 'DELETE'), [ "$OTHER_GW/web" ],
        'the Unstructured gateway.example.com Gateway web goes');
};

done_testing;
