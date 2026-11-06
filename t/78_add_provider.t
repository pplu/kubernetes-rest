#!/usr/bin/env perl
# karr k78: $api->add_provider(@providers) adds IO::K8s resource-map providers
# to a client that already exists.
#
# The POD told callers to add a class after construction with
# $api->resource_map->{Kind} = '+My::Class'. On the default client (map from
# the cluster, no map passed) that hash is built from discovery, and
# invalidate_discovery (which ensure_crd calls last) and absorb_discovery throw
# it away and rebuild it: the entry vanished, and the Kind either croaked as an
# unknown resource or came back as IO::K8s::Unstructured instead of the
# caller's class. `with` is the one registration every rebuild of the inner
# IO::K8s merges again, so add_provider appends to it - and, when the inner
# IO::K8s is already built, hands the providers to it at once. A call that
# finds nothing built sends no request and builds nothing.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use JSON::MaybeXS ();
use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::HTTPResponse;
use IO::K8s;

BEGIN {
    package My::K78::V1::Gizmo;
    use IO::K8s::APIObject
        api_version     => 'example.com/v1',
        resource_plural => 'gizmos';
    with 'IO::K8s::Role::Namespaced';
    k8s size => Int;
    $INC{'My/K78/V1/Gizmo.pm'} = 1;

    # A provider class: resource_map returns the Kinds it adds.
    package My::K78::Provider;
    sub new { bless {}, shift }
    sub resource_map { { Sprocket => '+My::K78::V1::Gizmo' } }
    $INC{'My/K78/Provider.pm'} = 1;

    # Loaded, but cannot be a provider: no new.
    package My::K78::NoNew;
    sub resource_map { {} }
    $INC{'My/K78/NoNew.pm'} = 1;
}

my $GIZMO = 'My::K78::V1::Gizmo';

# Records every request (METHOD /path).
{
    package Test::K78::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has calls => (is => 'ro', default => sub { [] });

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->calls }, $req->method . ' ' . $path;
        return $self->$orig($req);
    };
}

my $wire_json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

sub resource {
    my ($group, $plural, $kind) = @_;
    return {
        resource     => $plural,
        responseKind => { group => $group, version => 'v1', kind => $kind },
        scope        => 'Namespaced',
    };
}

sub aggregated {
    my ($group, @resources) = @_;
    return {
        kind       => 'APIGroupDiscoveryList',
        apiVersion => 'apidiscovery.k8s.io/v2',
        items      => [ { metadata => { name => $group },
                          versions => [ { version => 'v1', resources => \@resources } ] } ],
    };
}

# Discovery that does not list Gizmo, and one that does.
my $CORE       = aggregated('', resource('', 'pods', 'Pod'));
my $WITHOUT    = aggregated('example.com', resource('example.com', 'widgets', 'Widget'));
my $WITH_GIZMO = aggregated('example.com', resource('example.com', 'widgets', 'Widget'),
                                           resource('example.com', 'gizmos', 'Gizmo'));

sub response {
    return Kubernetes::REST::HTTPResponse->new(status => 200, content => $wire_json->encode($_[0]));
}

sub api {
    my (%args) = @_;
    my $io = Test::K78::IO->new;
    $io->add_response('GET', '/api',  $CORE);
    $io->add_response('GET', '/apis', $WITHOUT);
    $io->add_response('GET', '/apis/example.com/v1/namespaces/ns1/gizmos',
        { kind => 'GizmoList', apiVersion => 'example.com/v1', items => [
            { apiVersion => 'example.com/v1', kind => 'Gizmo', metadata => { name => 'g1', namespace => 'ns1' } } ] });
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => $io,
        %args,
    );
}

my $PROVIDER = { Gizmo => "+$GIZMO" };

# Build the map and the inner IO::K8s (resolving a name alone builds only the map).
sub built {
    my ($api) = @_;
    $api->new_object(Pod => { metadata => { name => 'p' } });
    return $api;
}

# add_provider, with a failure reported instead of ending the whole file.
sub add_to {
    my ($api, @providers) = @_;
    return $api->add_provider(@providers) if eval { $api->can('add_provider') };
    diag 'add_provider is not implemented';
    return;
}

subtest 'the card: a default client keeps the class across invalidate_discovery' => sub {
    my $api = api();
    is($api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod', 'the map is built from discovery');
    built($api);
    add_to($api, $PROVIDER);
    $api->invalidate_discovery;
    is($api->expand_class('Gizmo'), $GIZMO, 'Gizmo still resolves to the provider class');
    is($api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod', 'discovery Kinds still resolve');
};

subtest 'absorb_discovery keeps the class; without the provider it is Unstructured' => sub {
    my @docs = ('/api' => response($CORE), '/apis' => response($WITH_GIZMO));

    my $control = api();
    built($control);
    ok($control->absorb_discovery(@docs), 'control: absorbed');
    is($control->expand_class('Gizmo'), 'IO::K8s::Unstructured',
        'control: without the provider a discovered Kind is Unstructured');

    my $api = api();
    built($api);
    add_to($api, $PROVIDER);
    ok($api->absorb_discovery(@docs), 'absorbed');
    is($api->expand_class('Gizmo'), $GIZMO, 'with the provider it resolves to the provider class');
};

subtest 'a Kind discovery does not list resolves after invalidate_discovery' => sub {
    my $api = api();
    built($api);
    add_to($api, $PROVIDER);
    $api->invalidate_discovery;
    my $class = eval { $api->expand_class('Gizmo') };
    is($class, $GIZMO, 'no "unknown resource"') or diag $@;
};

subtest 'inner IO::K8s already built: the Kind resolves at once' => sub {
    my $api = api();
    built($api);
    ok($api->_has_k8s, 'the inner IO::K8s is built');
    add_to($api, $PROVIDER);
    is($api->expand_class('Gizmo'), $GIZMO, 'resolves without invalidate_discovery');
    is(eval { $api->new_object(Gizmo => { metadata => { name => 'g' } })->metadata->name }, 'g',
        'new_object builds the provider class');
};

subtest 'inner IO::K8s not built yet: no request, nothing built' => sub {
    my $api = api();
    ok(!$api->_has_k8s, 'precondition: nothing built');
    eval { $api->add_provider($PROVIDER); 1 } or diag $@;
    is_deeply($api->io->calls, [], 'no request was sent');
    ok(!$api->_has_k8s, 'the inner IO::K8s is still not built');
    is($api->expand_class('Gizmo'), $GIZMO, 'later resolution works');
};

subtest 'with, the provider forms, the return value' => sub {
    my $api = api(with => [ { Existing => '+My::Existing' } ]);
    my $hash = { Gizmo => "+$GIZMO" };
    my $ret = eval { $api->add_provider($hash, 'My::K78::Provider') };
    is($ret, $api, 'returns the client');
    is(scalar @{ $api->with }, 3, 'with grew by the two providers');
    is($api->with->[-2], $hash, 'with ends with the hashref ...');
    is($api->with->[-1], 'My::K78::Provider', '... and the provider class name');
    is($api->with->[0]{Existing}, '+My::Existing', 'earlier entries are kept');
    is($api->expand_class('Gizmo'), $GIZMO, 'the hashref works');
    is($api->expand_class('Sprocket'), $GIZMO, 'the provider class name works');

    my $obj_api = api();
    my $obj = bless {}, 'My::K78::Provider';
    eval { $obj_api->add_provider($obj) };
    is($obj_api->with->[-1], $obj, 'an object with resource_map is appended');
    is($obj_api->expand_class('Sprocket'), $GIZMO, 'and works');

    my $none = api();
    is(eval { $none->add_provider }, $none, 'no providers: still returns the client');

    # A class name that cannot act as a provider croaks at the call, naming the
    # method and not the value, and leaves `with` as it was.
    for my $bad ('My::K78::NoSuchProvider', 'My::K78::NoNew') {
        my $c = api(with => [ { Existing => '+My::Existing' } ]);
        my @before = @{ $c->with };
        my $ok = eval { $c->add_provider($bad); 1 };
        my $err = $@;
        ok(!$ok, "$bad: add_provider croaks");
        like($err, qr/add_provider/, "$bad: the message names add_provider");
        unlike($err, qr/\Q$bad\E/, "$bad: and does not contain the class name");
        is_deeply($c->with, \@before, "$bad: with is unchanged");
    }
};

subtest 'the request reaches the right path' => sub {
    my $api = api();
    built($api);
    eval { $api->add_provider($PROVIDER); 1 } or diag $@;
    $api->invalidate_discovery;
    my $list = eval { $api->list('Gizmo', namespace => 'ns1') } or diag $@;
    ok((grep { $_ eq 'GET /apis/example.com/v1/namespaces/ns1/gizmos' } @{ $api->io->calls }),
        'GET /apis/example.com/v1/namespaces/ns1/gizmos was sent')
        or diag explain $api->io->calls;
    $list or return;
    is(ref $list->items->[0], $GIZMO, 'the item is the provider class');
    is($list->items->[0]->metadata->name, 'g1', 'with the listed name');
};

subtest 'a client with a fixed resource_map' => sub {
    my $fixed = sub { api(resource_map => { %{ IO::K8s->default_resource_map } }) };

    my $api = $fixed->();
    eval { $api->add_provider($PROVIDER); 1 } or diag $@;
    is($api->expand_class('Gizmo'), $GIZMO, 'add_provider works on a fixed map');
    $api->invalidate_discovery;
    is($api->expand_class('Gizmo'), $GIZMO, '... and survives invalidate_discovery');

    # The documented recipe for a fixed map.
    my $recipe = $fixed->();
    $recipe->resource_map->{Gizmo} = "+$GIZMO";
    is($recipe->expand_class('Gizmo'), $GIZMO, 'recipe: the entry resolves');
    $recipe->invalidate_discovery;
    is($recipe->expand_class('Gizmo'), $GIZMO, 'recipe: survives invalidate_discovery');
    $recipe->absorb_discovery('/api' => response($CORE), '/apis' => response($WITH_GIZMO));
    is($recipe->expand_class('Gizmo'), $GIZMO, 'recipe: survives absorb_discovery');
};

done_testing;
