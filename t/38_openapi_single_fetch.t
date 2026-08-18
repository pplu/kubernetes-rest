#!/usr/bin/env perl
# karr #17: fetch_resource_map used to issue its own GET /openapi/v2 and
# decode the answer, while the lazy _openapi_spec attribute - what schema_for
# and compare_schema read - makes exactly the same request and caches it. A
# client on the default resource_map_from_cluster => 1 that also called
# schema_for() downloaded and decoded the multi-MB spec twice per process.
# The map is now built from _openapi_spec: one download, shared by all.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

# Mock IO that records every request it serves.
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

sub openapi_fetches {
    my ($io) = @_;
    return scalar grep { $_ eq 'GET /openapi/v2' } @{$io->calls};
}

my %OPENAPI_SPEC = (
    paths => {
        '/api/v1/namespaces/{namespace}/pods' => {
            get => {
                'x-kubernetes-group-version-kind' => {
                    group => '', version => 'v1', kind => 'Pod',
                },
            },
        },
    },
    definitions => {
        'io.k8s.api.core.v1.Pod' => {
            description => 'Pod is a collection of containers',
            properties => { metadata => {}, spec => {} },
        },
    },
);

subtest 'the spec is fetched once, however many readers it has' => sub {
    my $io = Counting::Mock::IO->new;
    $io->add_response('GET', '/openapi/v2', \%OPENAPI_SPEC);
    my $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io => $io,
    );

    my $map = $api->fetch_resource_map;
    is $map->{Pod}, 'Api::Core::V1::Pod', 'fetch_resource_map still builds the map';
    is openapi_fetches($io), 1, 'one /openapi/v2 download for the map';

    my $schema = $api->schema_for('io.k8s.api.core.v1.Pod');
    is $schema->{description}, 'Pod is a collection of containers',
        'schema_for answers from the same spec';
    is openapi_fetches($io), 1, 'and did not download it again';

    $api->fetch_resource_map;
    is openapi_fetches($io), 1,
        'a repeated fetch_resource_map rebuilds from the cached spec';
};

subtest 'the failure path keeps its documented wording' => sub {
    my $api = mock_api();
    # mock_api has no /openapi/v2 response -> 404
    throws_ok { $api->fetch_resource_map }
        qr/Could not load resource map from cluster:/,
        'fetch_resource_map croaks with its own message';
    like $@, qr/404/, 'and the underlying status rides along';
};

done_testing;
