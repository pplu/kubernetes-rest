#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Kubernetes::REST::CallContext;
use Kubernetes::REST::ListToRequest;

my $server = 'https://localhost:9999/';
package FakeCreds {
  use Moo;
  sub token { 'FakeToken' }
}

my $l2r = Kubernetes::REST::ListToRequest->new;

{
  my $call = Kubernetes::REST::CallContext->new(
    method => 'GetCoreAPIVersions',
    params => [ ],
    server => 'http://example.com',
    credentials => FakeCreds->new,
  );

  my $req = $l2r->params2request($call);
  cmp_ok($req->method, 'eq', 'GET');
  cmp_ok($req->url, 'eq', 'http://example.com/');
}

done_testing;
