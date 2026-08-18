#!/usr/bin/env perl
# karr #15: expand_class() used to be a plain delegation to the lazy k8s
# attribute, whose construction forces the resource_map - on the default
# resource_map_from_cluster => 1 that is a full GET /openapi/v2 per process,
# paid for resolving a name like 'Pod' whose answer already sits in the
# built-in IO::K8s map. Pure name resolution must not cost a cluster
# roundtrip; only a name the built-in map cannot answer may fetch the map.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Kubernetes::Mock ();
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

my %OPENAPI_SPEC = (
    paths => {
        '/api/v1/namespaces/{namespace}/pods' => {
            get => {
                'x-kubernetes-group-version-kind' => {
                    group => '', version => 'v1', kind => 'Pod',
                },
            },
        },
        '/apis/example.com/v1/widgets' => {
            get => {
                'x-kubernetes-group-version-kind' => {
                    group => 'example.com', version => 'v1', kind => 'Widget',
                },
            },
        },
    },
);

sub cluster_api {
    my (%extra) = @_;
    my $io = Counting::Mock::IO->new;
    $io->add_response('GET', '/openapi/v2', \%OPENAPI_SPEC);
    my $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io => $io,
        %extra,
    );
    return ($api, $io);
}

subtest 'built-in names resolve without any cluster roundtrip' => sub {
    my ($api, $io) = cluster_api();

    is $api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'short name resolves from the built-in map';
    is $api->expand_class('Pod', 'v1'), 'IO::K8s::Api::Core::V1::Pod',
        'GVK-qualified name resolves from the built-in map';
    is $api->expand_class('+My::Own::Widget'), 'My::Own::Widget',
        '+class is returned as-is without loading it';
    is $api->expand_class('IO::K8s::Api::Apps::V1::Deployment'),
        'IO::K8s::Api::Apps::V1::Deployment',
        'full class name is returned as-is';

    is_deeply $io->calls, [], 'no HTTP request was made for any of it';
};

subtest 'a name the built-in map cannot answer still fetches the cluster map' => sub {
    my ($api, $io) = cluster_api();

    is $api->expand_class('Widget'), 'IO::K8s::Api::Example::V1::Widget',
        'unknown Kind falls through to the cluster-derived map';
    is scalar(grep { $_ eq 'GET /openapi/v2' } @{$io->calls}), 1,
        'exactly one /openapi/v2 fetch for the fallthrough';

    # Once the map is fetched, resolution goes through it - as before #15.
    is $api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'built-in name still resolves after the map is loaded';
    is scalar(grep { $_ eq 'GET /openapi/v2' } @{$io->calls}), 1,
        'and the spec is not fetched again';
};

subtest 'a caller-supplied resource_map is never shadowed by the built-in map' => sub {
    my ($api, $io) = cluster_api(
        resource_map => {
            %{ IO::K8s->default_resource_map },
            Pod => '+My::Custom::Pod',
        },
    );

    is $api->expand_class('Pod'), 'My::Custom::Pod',
        'the custom mapping wins over the built-in one';
    is_deeply $io->calls, [], 'still no HTTP request';
};

subtest 'resource_map_from_cluster => 0 keeps resolving locally' => sub {
    my ($api, $io) = cluster_api(resource_map_from_cluster => 0);

    is $api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'short name resolves from the default map';
    is_deeply $io->calls, [], 'no HTTP request';
};

done_testing;
