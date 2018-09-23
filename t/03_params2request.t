#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Kubernetes::REST::ListToRequest;

my $l2r = Kubernetes::REST::ListToRequest->new;

{
  my $req = $l2r->params2request('GetCoreAPIVersions', []);
  cmp_ok($req->method, 'eq', 'GET');
}

done_testing;
