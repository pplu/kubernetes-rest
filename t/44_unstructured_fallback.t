#!/usr/bin/env perl
# karr k24 / design D16 (D13 rung 4): the Unstructured fallback for
# discovery-confirmed Kinds.
#
# A GVK the cluster reports through aggregated discovery, but which resolves to
# no shipped class, no `with` provider and no AutoGen'd class, becomes
# IO::K8s::Unstructured in Kubernetes::REST -- on by DEFAULT (no opt-in), but
# GATED on discovery confirmation. Path building for it takes the resource
# plural and the namespaced/cluster scope from the discovery catalog, because
# Unstructured carries no api_version()/resource_plural()/Namespaced role of
# its own (its apiVersion/kind are data on the instance, not class identity).
#
# The contrast this file pins:
#   - a Kind discovery serves, with nothing else to resolve it, USED to fail
#     closed (the fabricated IO::K8s::<Kind> name that cannot load, per C);
#     with E it resolves to IO::K8s::Unstructured instead (rung 4).
#   - a Kind discovery does NOT serve still fails closed (rung 5).
#   - rungs 1-3 (a `with` provider, a builtin) still win ahead of Unstructured.
#   - the fetch-free cheap path (t/36) is untouched: resolving Pod or a +class
#     never queries discovery.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

# Mock IO that records every request (METHOD PATH), as in t/36/t/41.
{
    package Counting::Mock::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has calls => (is => 'ro', default => sub { [] });

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url // '') =~ s{^https?://[^/]+}{};
        push @{$self->calls}, ($req->method // 'GET') . ' ' . $path;
        return $self->$orig($req);
    };
}

sub count_calls {
    my ($io, $wanted) = @_;
    return scalar grep { $_ eq $wanted } @{$io->calls};
}

# ---------------------------------------------------------------------------
# Aggregated discovery v2 (APIGroupDiscoveryList).
# ---------------------------------------------------------------------------

# GET /api -> the core group, so a core Kind has a real discovery entry too.
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

# GET /apis -> foreign group 'example.com' (no bundled class, no provider,
# no spec) serving a namespaced Widget and a cluster-scoped ClusterWidget, plus
# the Gateway API group (a bundled provider exists for it) to prove rung 2 wins.
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
                            resource     => 'clusterwidgets',
                            responseKind => { group => 'example.com', version => 'v1', kind => 'ClusterWidget' },
                            scope        => 'Cluster',
                        },
                    ],
                },
            ],
        },
        {
            metadata => { name => 'gateway.networking.k8s.io' },
            versions => [
                {
                    version   => 'v1',
                    resources => [
                        {
                            resource     => 'gateways',
                            responseKind => { group => 'gateway.networking.k8s.io', version => 'v1', kind => 'Gateway' },
                            scope        => 'Namespaced',
                        },
                    ],
                },
            ],
        },
    ],
);

sub disco_api {
    my (%extra) = @_;
    my $io = Counting::Mock::IO->new;
    $io->add_response('GET', '/api',  \%CORE_DISCOVERY);
    $io->add_response('GET', '/apis', \%GROUPED_DISCOVERY);
    my $api = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $io,
        %extra,
    );
    return ($api, $io);
}

# ---------------------------------------------------------------------------
# The core of E: a discovery-confirmed foreign Kind resolves to Unstructured.
# ---------------------------------------------------------------------------
subtest 'D16 rung 4: a discovery-confirmed foreign Kind resolves to Unstructured' => sub {
    my ($api, $io) = disco_api();

    is $api->expand_class('Widget'), 'IO::K8s::Unstructured',
        'Widget (in discovery, no class/provider/spec) resolves to Unstructured';
    is $api->expand_class('ClusterWidget'), 'IO::K8s::Unstructured',
        'the cluster-scoped Kind resolves to Unstructured too';

    # Discovery was fetched (to confirm the GVK), /openapi/v2 was not.
    is count_calls($io, 'GET /apis'), 1, 'discovery fetched once for the fallthrough';
    is count_calls($io, 'GET /openapi/v2'), 0, 'never touched /openapi/v2';
};

# ---------------------------------------------------------------------------
# Path building for Unstructured pulls plural + scope from the catalog.
# ---------------------------------------------------------------------------
subtest 'build_path takes plural and scope from discovery for Unstructured' => sub {
    my ($api) = disco_api();

    my $class = $api->expand_class('Widget');

    # Namespaced: /apis/<group>/<version>/namespaces/<ns>/<plural>/<name>.
    # The plural ('widgets') and the namespaced scope both come from discovery,
    # NOT from the Unstructured class (which knows neither). The seam consumer
    # passes the Kind via `kind => ...` (what the CRUD methods thread in).
    is $api->build_path($class, name => 'w1', namespace => 'ns', kind => 'Widget'),
        '/apis/example.com/v1/namespaces/ns/widgets/w1',
        'namespaced Unstructured path uses the discovery plural and scope';

    is $api->build_path($class, namespace => 'ns', kind => 'Widget'),
        '/apis/example.com/v1/namespaces/ns/widgets',
        'the collection path for a namespaced Unstructured Kind';

    # Cluster-scoped: the namespace is dropped even when one is passed, because
    # discovery reports scope Cluster for ClusterWidget.
    is $api->build_path($class, name => 'cw1', namespace => 'ns', kind => 'ClusterWidget'),
        '/apis/example.com/v1/clusterwidgets/cw1',
        'cluster-scoped Unstructured path omits the namespace segment';

    # Without a Kind, build_path for Unstructured cannot know the resource.
    throws_ok { $api->build_path($class, name => 'w1') }
        qr/needs a Kind/,
        'build_path croaks for Unstructured without a Kind';
};

# ---------------------------------------------------------------------------
# A full CRUD round-trip through the pipeline: get() -> Unstructured object.
# ---------------------------------------------------------------------------
subtest 'get() inflates an Unstructured object with apiVersion/kind from data' => sub {
    my ($api, $io) = disco_api();

    $io->add_response('GET', '/apis/example.com/v1/namespaces/ns/widgets/w1', {
        apiVersion => 'example.com/v1',
        kind       => 'Widget',
        metadata   => { name => 'w1', namespace => 'ns' },
        spec       => { color => 'blue', size => 7 },
    });

    my $obj = $api->get('Widget', 'w1', namespace => 'ns');
    isa_ok $obj, 'IO::K8s::Unstructured', 'the returned object';
    is $obj->kind, 'Widget', 'kind comes from the response body';
    is $obj->apiVersion, 'example.com/v1', 'apiVersion comes from the response body';
    is $obj->metadata->name, 'w1', 'metadata.name inflated';

    # The GET landed on the discovery-derived path (namespaced, plural widgets).
    is count_calls($io, 'GET /apis/example.com/v1/namespaces/ns/widgets/w1'), 1,
        'the request used the discovery-built path';

    # The opaque spec round-trips through the unknown-fields bag.
    is $obj->TO_JSON->{spec}{color}, 'blue', 'the opaque spec is preserved on the object';
};

subtest 'list() inflates a list of Unstructured objects' => sub {
    my ($api, $io) = disco_api();

    $io->add_response('GET', '/apis/example.com/v1/namespaces/ns/widgets', {
        apiVersion => 'example.com/v1',
        kind       => 'WidgetList',
        items      => [
            { apiVersion => 'example.com/v1', kind => 'Widget',
              metadata => { name => 'a', namespace => 'ns' }, spec => { color => 'red' } },
            { apiVersion => 'example.com/v1', kind => 'Widget',
              metadata => { name => 'b', namespace => 'ns' }, spec => { color => 'green' } },
        ],
    });

    my $list = $api->list('Widget', namespace => 'ns');
    is scalar($list->items->@*), 2, 'two items inflated';
    isa_ok $list->items->[0], 'IO::K8s::Unstructured', 'first item';
    is $list->items->[1]->metadata->name, 'b', 'second item name';
    is count_calls($io, 'GET /apis/example.com/v1/namespaces/ns/widgets'), 1,
        'the list request used the discovery-built collection path';
};

# ---------------------------------------------------------------------------
# Rung 5 still holds: a Kind discovery does not serve stays fail-closed.
# ---------------------------------------------------------------------------
subtest 'a Kind not in discovery stays fail-closed (rung 5, not Unstructured)' => sub {
    my ($api) = disco_api();

    # 'Ghost' is in no group discovery reports. It must NOT become Unstructured;
    # the fabricated IO::K8s::Ghost name is kept so the load error names it.
    my $resolved = $api->expand_class('Ghost');
    isnt $resolved, 'IO::K8s::Unstructured',
        'an unknown Kind is not diverted to Unstructured';
    is $resolved, 'IO::K8s::Ghost',
        'the fail-open bare name is returned unchanged (fails closed at use)';

    throws_ok { $api->get('Ghost', 'g1', namespace => 'ns') }
        qr/Ghost/,
        'using the unresolved Kind fails closed, naming the Kind';
};

# ---------------------------------------------------------------------------
# Rung 2 wins: a `with` provider resolves the Kind before Unstructured.
# ---------------------------------------------------------------------------
subtest 'a `with` provider wins over Unstructured (rung 2 before rung 4)' => sub {
    plan skip_all => 'IO::K8s::GatewayAPI not available'
        unless eval { require IO::K8s::GatewayAPI; 1 };

    my ($api) = disco_api(with => ['IO::K8s::GatewayAPI']);

    # Gateway is served by discovery AND provided by IO::K8s::GatewayAPI: the
    # provider class must win, not Unstructured.
    is $api->expand_class('Gateway'), 'IO::K8s::GatewayAPI::V1::Gateway',
        'the provider Kind resolves to the provider class, not Unstructured';

    # And a foreign Kind the provider does NOT supply still becomes Unstructured.
    is $api->expand_class('Widget'), 'IO::K8s::Unstructured',
        'a Kind the provider does not cover still falls to Unstructured';
};

# ---------------------------------------------------------------------------
# Core kinds are unchanged.
# ---------------------------------------------------------------------------
subtest 'core kinds resolve to their typed classes, unchanged' => sub {
    my ($api) = disco_api();

    is $api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'a core Kind resolves to its typed class, never Unstructured';
    is $api->expand_class('Namespace'), 'IO::K8s::Api::Core::V1::Namespace',
        'another core Kind resolves typed';
};

# ---------------------------------------------------------------------------
# The fetch-free cheap path (t/36) is untouched: Unstructured only engages on
# the cluster-backed fallthrough, never for a name the built-in map answers.
# ---------------------------------------------------------------------------
subtest 'the cheap path stays fetch-free (no discovery for Pod or a +class)' => sub {
    my ($api, $io) = disco_api();

    is $api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod', 'Pod from the built-in map';
    is $api->expand_class('+My::Own::Widget'), 'My::Own::Widget', '+class returned as-is';

    is_deeply $io->calls, [], 'neither resolution made any HTTP request';
};

# ---------------------------------------------------------------------------
# resource_map_from_cluster => 0: no cluster, so no discovery confirmation ->
# an unknown Kind stays fail-closed rather than becoming Unstructured.
# ---------------------------------------------------------------------------
subtest 'without a cluster (resource_map_from_cluster => 0) there is no Unstructured' => sub {
    my ($api, $io) = disco_api(resource_map_from_cluster => 0);

    isnt $api->expand_class('Widget'), 'IO::K8s::Unstructured',
        'no discovery to confirm the GVK -> not Unstructured';
    is_deeply $io->calls, [], 'and nothing was fetched';
};

done_testing;
