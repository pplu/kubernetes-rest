#!/usr/bin/env perl
# Live integration test for the Kubernetes Watch API.
#
# Requires a running cluster:
#   TEST_KUBERNETES_REST_KUBECONFIG=~/.kube/config prove -lv t/11_watch_live.t

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(live_api is_live);

unless (is_live()) {
    plan skip_all => 'Set TEST_KUBERNETES_REST_KUBECONFIG for live watch tests';
}

my $api = eval { live_api() };
if ($@) {
    plan skip_all => "No cluster available: $@";
}

plan tests => 2;

# === Test 1: Watch pods in kube-system with short timeout ===
subtest 'watch kube-system pods' => sub {
    my @events;
    my $last_rv = eval {
        $api->watch('Pod',
            namespace => 'kube-system',
            timeout   => 5,
            on_event  => sub {
                my ($event) = @_;
                push @events, $event;
            },
        );
    };

    if ($@) {
        diag "Watch error: $@";
        fail('watch completed without error');
        return;
    }

    ok(scalar @events > 0, 'received at least one event');
    diag "Received " . scalar(@events) . " events";

    # Verify first event structure
    my $first = $events[0];
    ok($first->type, 'event has type');
    like($first->type, qr/^(ADDED|MODIFIED|DELETED|BOOKMARK)$/, 'valid event type');
    diag "First event: " . $first->type . " " . ($first->object->metadata->name // 'unknown');

    # ADDED events should arrive for existing pods
    my @added = grep { $_->type eq 'ADDED' } @events;
    ok(scalar @added > 0, 'got ADDED events for existing pods');

    # Verify object inflation
    for my $ev (@added[0 .. ($#added > 2 ? 2 : $#added)]) {
        isa_ok($ev->object, 'IO::K8s::Api::Core::V1::Pod', 'inflated Pod object');
        ok($ev->object->metadata->name, 'pod has name');
        ok($ev->object->metadata->namespace, 'pod has namespace');
        diag "  Pod: " . $ev->object->metadata->name;
    }

    # resourceVersion should be returned
    ok(defined $last_rv, 'last resourceVersion returned');
    diag "Last resourceVersion: $last_rv";
};

# === Test 2: Watch namespaces (cluster-scoped, no namespace param) ===
subtest 'watch namespaces' => sub {
    my @events;
    my $last_rv = eval {
        $api->watch('Namespace',
            timeout  => 5,
            on_event => sub { push @events, $_[0] },
        );
    };

    if ($@) {
        diag "Watch error: $@";
        fail('watch completed without error');
        return;
    }

    ok(scalar @events > 0, 'received namespace events');

    my @added = grep { $_->type eq 'ADDED' } @events;
    my %names = map { $_->object->metadata->name => 1 } @added;
    ok($names{default}, 'got ADDED for default namespace');
    ok($names{'kube-system'}, 'got ADDED for kube-system namespace');

    ok(defined $last_rv, 'resourceVersion returned');
};

done_testing;
