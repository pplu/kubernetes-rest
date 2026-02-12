package Kubernetes::REST::Coordination;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Coordination' });
1;
