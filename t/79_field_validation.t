#!/usr/bin/env perl
# karr k79: fieldValidation on writes.
#
# A client that does not ask for strict field validation gets unknown fields
# dropped by the API server, which says so only in a response header - an
# OCPNode stored without spec.nodeIP, the node joined on the wrong address, and
# nothing here showed the caller. A write now takes the query parameter
# fieldValidation (Strict, Warn or Ignore) per request, as the option
# `fieldValidation` of create, update, patch, patch_status and update_status,
# and per client as the attribute `field_validation`; the request wins over
# the client. Exactly the writes (POST/PUT/PATCH) carry it - get, list and
# delete never do, whatever the client default - and with neither set the URL
# has no fieldValidation at all. A value other than the three croaks naming the
# option and the allowed values, never the value; an option a write does not
# take croaks as before. Every croak comes before anything is sent. ensure()
# reaches it through its create and update, with the client default only.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use JSON::MaybeXS ();
use Kubernetes::REST;
use Kubernetes::REST::HTTPResponse;

my $wire_json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
my $BAD = 'Strictest-9f2';
my $PODS = 'http://mock.local/api/v1/namespaces/default/pods';
my $POD  = {
    apiVersion => 'v1', kind => 'Pod',
    metadata   => { name => 'p1', namespace => 'default' },
    spec       => { containers => [ { name => 'c', image => 'i' } ] },
};

# A transport that records "METHOD full-url" for every request. GET of the pod
# answers 200 unless `missing` is set, then 404; everything else answers 200
# with a Pod (a PodList for the collection GET).
{
    package Test::K79::IO;
    use Moo;
    with 'Kubernetes::REST::Role::IO';

    has requests => (is => 'ro', default => sub { [] });
    has missing  => (is => 'rw', default => sub { 0 });

    sub call {
        my ($self, $req) = @_;
        push @{ $self->requests }, $req->method . ' ' . $req->url;
        my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
        my ($method, $path) = ($req->method, $req->url);
        $path =~ s/\?.*//;
        return Kubernetes::REST::HTTPResponse->new(status => 404,
            content => '{"kind":"Status","status":"Failure","reason":"NotFound","code":404}')
            if $method eq 'GET' and $self->missing and $path =~ m{/pods/p1\z};
        return Kubernetes::REST::HTTPResponse->new(status => 200,
            content => $json->encode({ apiVersion => 'v1', kind => 'PodList', items => [ $POD ] }))
            if $method eq 'GET' and $path =~ m{/pods\z};
        return Kubernetes::REST::HTTPResponse->new(status => 200,
            content => $json->encode($method eq 'DELETE'
                ? { kind => 'Status', apiVersion => 'v1', status => 'Success' } : $POD));
    }
    sub call_streaming { die 'not used' }
}

sub api {
    my (%args) = @_;
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => Test::K79::IO->new,
        resource_map_from_cluster => 0,
        %args,
    );
}

sub pod { $_[0]->new_object(Pod => $POD) }

# The five writes: label, expected "METHOD url-without-query", code.
my @WRITES = (
    [ 'create',       "POST $PODS",            sub { my ($a, @o) = @_; $a->create(pod($a), @o) } ],
    [ 'update',       "PUT $PODS/p1",          sub { my ($a, @o) = @_; $a->update(pod($a), @o) } ],
    [ 'patch (class and name)', "PATCH $PODS/p1",
        sub { my ($a, @o) = @_; $a->patch('Pod', 'p1', namespace => 'default', patch => { metadata => { labels => { a => 'b' } } }, @o) } ],
    [ 'patch (object)', "PATCH $PODS/p1",
        sub { my ($a, @o) = @_; $a->patch(pod($a), patch => { metadata => { labels => { a => 'b' } } }, @o) } ],
    [ 'patch_status', "PATCH $PODS/p1/status",
        sub { my ($a, @o) = @_; $a->patch_status('Pod', 'p1', namespace => 'default', patch => { status => { phase => 'Running' } }, @o) } ],
    [ 'update_status', "PUT $PODS/p1/status",  sub { my ($a, @o) = @_; $a->update_status(pod($a), @o) } ],
);

# Run $code; return the requests it sent and the error it died with, if any.
sub sent {
    my ($api, $code) = @_;
    @{ $api->io->requests } = ();
    my $ok = eval { $code->(); 1 };
    return ([ @{ $api->io->requests } ], $ok ? undef : "$@");
}

subtest 'per request: every write carries fieldValidation=Strict' => sub {
    for my $w (@WRITES) {
        my ($label, $expect, $code) = @$w;
        my $api = api();
        my ($sent, $err) = sent($api, sub { $code->($api, fieldValidation => 'Strict') });
        is_deeply($sent, ["$expect?fieldValidation=Strict"], "$label: method, path and query")
            or diag $err;
    }
};

subtest 'client default reaches every write' => sub {
    for my $w (@WRITES) {
        my ($label, $expect, $code) = @$w;
        my $api = api(field_validation => 'Warn');
        my ($sent, $err) = sent($api, sub { $code->($api) });
        is_deeply($sent, ["$expect?fieldValidation=Warn"], "$label: Warn from the client")
            or diag $err;
    }
};

subtest 'ensure() reaches it through create and update, client default only' => sub {
    my $api = api(field_validation => 'Warn');
    $api->io->missing(1);
    my ($sent, $err) = sent($api, sub { $api->ensure($POD) });
    is_deeply($sent, [ "GET $PODS/p1", "POST $PODS?fieldValidation=Warn" ],
        'ensure creating: the GET carries none, the POST carries Warn') or diag $err;

    $api->io->missing(0);
    ($sent, $err) = sent($api, sub { $api->ensure($POD) });
    is_deeply([ grep { /\AGET / } @$sent ], [ "GET $PODS/p1" ], 'ensure updating: the GET carries none');
    is_deeply([ grep { /\APUT / } @$sent ], [ "PUT $PODS/p1?fieldValidation=Warn" ],
        'ensure updating: the PUT carries Warn') or diag $err;
};

subtest 'per request wins over the client default' => sub {
    for my $w (@WRITES) {
        my ($label, $expect, $code) = @$w;
        my $api = api(field_validation => 'Warn');
        my ($sent, $err) = sent($api, sub { $code->($api, fieldValidation => 'Ignore') });
        is_deeply($sent, ["$expect?fieldValidation=Ignore"], "$label: Ignore beats Warn")
            or diag $err;
    }
};

subtest 'nothing set: no fieldValidation anywhere' => sub {
    for my $w (@WRITES) {
        my ($label, $expect, $code) = @$w;
        my $api = api();
        my ($sent, $err) = sent($api, sub { $code->($api) });
        is_deeply($sent, [$expect], "$label: the URL has no query") or diag $err;
    }
    my $api = api();
    $api->io->missing(1);
    my ($sent) = sent($api, sub { $api->ensure($POD) });
    is_deeply($sent, [ "GET $PODS/p1", "POST $PODS" ], 'ensure: no query on either request');
};

subtest 'reads and deletes never carry it, even with a client default' => sub {
    my $api = api(field_validation => 'Strict');
    my ($sent, $err) = sent($api, sub {
        $api->get('Pod', 'p1', namespace => 'default');
        $api->list('Pod', namespace => 'default');
        $api->delete('Pod', 'p1', namespace => 'default');
    });
    is_deeply($sent, [ "GET $PODS/p1", "GET $PODS", "DELETE $PODS/p1" ],
        'get, list and delete: no query at all') or diag $err;
};

subtest 'a bad client default croaks at construction without naming the value' => sub {
    my $api = eval { api(field_validation => $BAD) };
    my $err = $@;
    ok(!$api, 'construction dies');
    like($err, qr/field_validation/, 'names the attribute');
    like($err, qr/Strict.*Warn.*Ignore/s, 'lists the allowed values');
    unlike($err, qr/\Q$BAD\E/, 'does not contain the given value');
    for my $good (qw(Strict Warn Ignore)) {
        ok(eval { api(field_validation => $good) }, "$good is accepted");
    }
};

subtest 'a bad per-request value croaks before anything is sent' => sub {
    for my $w (@WRITES) {
        my ($label, undef, $code) = @$w;
        my $api = api();
        my ($sent, $err) = sent($api, sub { $code->($api, fieldValidation => $BAD) });
        ok(defined $err, "$label: dies") or next;
        like($err, qr/fieldValidation/, "$label: names the option");
        like($err, qr/Strict.*Warn.*Ignore/s, "$label: lists the allowed values");
        unlike($err, qr/\Q$BAD\E/, "$label: does not contain the value");
        is_deeply($sent, [], "$label: nothing was sent");
    }
};

subtest 'an option a write does not take still croaks before sending' => sub {
    for my $case ([ create => sub { $_[0]->create(pod($_[0]), bogus => 1) } ],
                  [ update => sub { $_[0]->update(pod($_[0]), bogus => 1) } ],
                  [ update_status => sub { $_[0]->update_status(pod($_[0]), bogus => 1) } ]) {
        my ($label, $code) = @$case;
        my $api = api();
        my ($sent, $err) = sent($api, sub { $code->($api) });
        like($err, qr/Unknown argument 'bogus' to \Q$label\E\(\)/, "$label: names the argument") or next;
        is_deeply($sent, [], "$label: nothing was sent");
    }
};

done_testing;
