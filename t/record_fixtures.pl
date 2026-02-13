#!/usr/bin/env perl
# Record responses from a live cluster for use in mock tests
#
# Usage: perl t/record_fixtures.pl
#
# Requires a working kubeconfig with cluster access

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../../io-k8s-p5/lib";

use JSON::MaybeXS;
use Path::Tiny qw(path);
use Kubernetes::REST::Kubeconfig;

my $mock_dir = path($FindBin::Bin)->child('mock');
$mock_dir->mkpath;

my $json = JSON::MaybeXS->new->pretty->canonical;

my $kubeconfig = $ENV{TEST_KUBERNETES_REST_KUBECONFIG}
    or die "Usage: TEST_KUBERNETES_REST_KUBECONFIG=/path/to/kubeconfig perl $0\n";

print "Connecting to cluster using $kubeconfig...\n";
my $api = eval { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $kubeconfig)->api };
if ($@) {
    die "Could not connect to cluster: $@\n";
}

print "Cluster version: ", $api->cluster_version, "\n\n";

# Things that exist in every cluster
my @fixtures = (
    # Namespaces - always exist
    { name => 'get_api_v1_namespaces', call => sub { $api->list('Namespace') } },
    { name => 'get_api_v1_namespaces_default', call => sub { $api->get('Namespace', 'default') } },
    { name => 'get_api_v1_namespaces_kube-system', call => sub { $api->get('Namespace', 'kube-system') } },

    # Nodes
    { name => 'get_api_v1_nodes', call => sub { $api->list('Node') } },

    # Services - kubernetes service always exists
    { name => 'get_api_v1_namespaces_default_services', call => sub { $api->list('Service', namespace => 'default') } },
    { name => 'get_api_v1_namespaces_default_services_kubernetes', call => sub { $api->get('Service', 'kubernetes', namespace => 'default') } },

    # ConfigMaps in kube-system
    { name => 'get_api_v1_namespaces_kube-system_configmaps', call => sub { $api->list('ConfigMap', namespace => 'kube-system') } },

    # ServiceAccounts
    { name => 'get_api_v1_namespaces_default_serviceaccounts', call => sub { $api->list('ServiceAccount', namespace => 'default') } },
    { name => 'get_api_v1_namespaces_default_serviceaccounts_default', call => sub { $api->get('ServiceAccount', 'default', namespace => 'default') } },

    # Cluster info
    { name => 'get_version', call => sub {
        # Raw request for version
        my $resp = $api->_request('GET', '/version');
        return $json->decode($resp->content);
    }},
);

for my $fixture (@fixtures) {
    print "Recording: $fixture->{name}... ";
    my $result = eval { $fixture->{call}->() };
    if ($@) {
        print "FAILED: $@\n";
        next;
    }

    my $data = ref($result) && $result->can('TO_JSON') ? $result->TO_JSON : $result;
    my $file = $mock_dir->child("$fixture->{name}.json");
    $file->spew_utf8($json->encode($data));
    print "OK\n";
}

print "\nDone! Fixtures saved to $mock_dir\n";
