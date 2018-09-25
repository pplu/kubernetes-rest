#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Kubernetes::REST::ListToRequest;

my $server = 'https://localhost:9999/';
package FakeCreds {
  use Moo;
  sub token { 'FakeToken' }
}

my $l2r = Kubernetes::REST::ListToRequest->new;

{
  my $req = $l2r->params2request(
    'GetCoreAPIVersions',
    $server,
    FakeCreds->new,
    []
  );
  cmp_ok($req->method, 'eq', 'GET');
}

done_testing;
