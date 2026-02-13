#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;

# Test that error responses are handled correctly
# (actual API calls would require a real cluster, so we just test setup)
{
    my $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://example.com'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'FakeToken'),
        resource_map_from_cluster => 0,
    );

    # Verify API object is created correctly
    ok($api, 'API object created');
    is($api->server->endpoint, 'http://example.com', 'Server endpoint set correctly');
    is($api->credentials->token, 'FakeToken', 'Credentials set correctly');
}

# Test error handling for missing parameters
{
    my $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://example.com'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'FakeToken'),
        resource_map_from_cluster => 0,
    );

    throws_ok(
        sub { $api->get('Pod') },
        qr/name required/,
        'get without name throws error'
    );

    throws_ok(
        sub { $api->delete('Pod') },
        qr/name required/,
        'delete without name throws error'
    );
}

done_testing;
