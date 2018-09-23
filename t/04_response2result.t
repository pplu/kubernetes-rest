#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Kubernetes::REST::Result2Hash;
use Kubernetes::REST::HTTPResponse;

my $l2r = Kubernetes::REST::Result2Hash->new;

{
  my $res = $l2r->result2return(
    Kubernetes::REST::HTTPResponse->new(

    )
  );
}

done_testing;
