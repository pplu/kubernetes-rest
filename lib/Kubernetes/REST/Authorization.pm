package Kubernetes::REST::Authorization;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Authorization' });
1;
