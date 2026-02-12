#!/usr/bin/env perl
# Tests for API operations - works with mock or live cluster
#
# Run with mock (default, safe):
#   prove -l t/05_api_operations.t
#
# Run against live cluster (requires explicit kubeconfig path):
#   TEST_KUBERNETES_REST_KUBECONFIG=/path/to/kubeconfig prove -l t/05_api_operations.t

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api live_api is_live);

my $api;
if (is_live()) {
    diag "Running against LIVE cluster: $ENV{TEST_KUBERNETES_REST_KUBECONFIG}";
    $api = eval { live_api() };
    if ($@) {
        plan skip_all => "No cluster available: $@";
    }
} else {
    diag "Running with MOCK responses";
    diag "Set TEST_KUBERNETES_REST_KUBECONFIG=/path/to/kubeconfig for live tests";
    $api = mock_api();
}

# Check if we have mock data
my $mock_dir = "$FindBin::Bin/mock";
unless (is_live() || -f "$mock_dir/get_api_v1_namespaces_default.json") {
    plan skip_all => "No mock data. Run: perl t/record_fixtures.pl";
}

plan tests => 10;

# Test 1: API object exists
ok($api, 'API object created');

# Test 2: List namespaces
subtest 'list namespaces' => sub {
    my $list = $api->list('Namespace');
    ok($list, 'got namespace list');
    ok($list->can('items'), 'result has items method');
    my @items = @{$list->items // []};
    ok(@items > 0, 'has at least one namespace');

    # Check for standard namespaces
    my %names = map { $_->metadata->name => 1 } @items;
    ok($names{default}, 'has default namespace');
    ok($names{'kube-system'}, 'has kube-system namespace');
};

# Test 3: Get specific namespace
subtest 'get namespace' => sub {
    my $ns = $api->get('Namespace', 'default');
    ok($ns, 'got default namespace');
    is($ns->metadata->name, 'default', 'name is default');
    is($ns->kind, 'Namespace', 'kind is Namespace');
};

# Test 4: List services in default namespace
subtest 'list services' => sub {
    my $list = $api->list('Service', namespace => 'default');
    ok($list, 'got service list');
    my @items = @{$list->items // []};
    ok(@items > 0, 'has at least one service');

    # kubernetes service should exist
    my %names = map { $_->metadata->name => 1 } @items;
    ok($names{kubernetes}, 'has kubernetes service');
};

# Test 5: Get kubernetes service
subtest 'get service' => sub {
    my $svc = $api->get('Service', 'kubernetes', namespace => 'default');
    ok($svc, 'got kubernetes service');
    is($svc->metadata->name, 'kubernetes', 'name is kubernetes');
    is($svc->kind, 'Service', 'kind is Service');
    ok($svc->spec->ports, 'has ports');
};

# Test 6: List nodes
subtest 'list nodes' => sub {
    my $list = $api->list('Node');
    ok($list, 'got node list');
    # Empty cluster might have no nodes ready yet, but list should work
    ok($list->can('items'), 'result has items method');
};

# Test 7: List service accounts
subtest 'list service accounts' => sub {
    my $list = $api->list('ServiceAccount', namespace => 'default');
    ok($list, 'got service account list');
    my @items = @{$list->items // []};
    ok(@items > 0, 'has at least one service account');

    # default service account should exist
    my %names = map { $_->metadata->name => 1 } @items;
    ok($names{default}, 'has default service account');
};

# Test 8: Get service account
subtest 'get service account' => sub {
    my $sa = $api->get('ServiceAccount', 'default', namespace => 'default');
    ok($sa, 'got default service account');
    is($sa->metadata->name, 'default', 'name is default');
    is($sa->kind, 'ServiceAccount', 'kind is ServiceAccount');
};

# Test 9: Object serialization roundtrip
subtest 'serialization roundtrip' => sub {
    my $ns = $api->get('Namespace', 'default');
    my $json_data = $ns->TO_JSON;
    ok($json_data, 'TO_JSON works');
    is($json_data->{kind}, 'Namespace', 'kind preserved');
    is($json_data->{metadata}{name}, 'default', 'name preserved');

    # Re-inflate
    my $ns2 = $api->inflate($json_data);
    ok($ns2, 'inflate works');
    is($ns2->metadata->name, 'default', 'roundtrip preserves data');
};

# Test 10: Schema comparison (if live)
subtest 'schema comparison' => sub {
    plan skip_all => 'Schema comparison requires live cluster' unless is_live();

    my $diff = $api->compare_schema('Namespace');
    ok($diff, 'compare_schema works');
    is(ref($diff), 'HASH', 'returns hashref');
    ok(exists $diff->{missing_locally}, 'has missing_locally');
    ok(exists $diff->{missing_in_schema}, 'has missing_in_schema');
    ok(exists $diff->{type_mismatch}, 'has type_mismatch');
};

done_testing;
