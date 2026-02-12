package Kubernetes::REST::Policy;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Policy' });
1;
