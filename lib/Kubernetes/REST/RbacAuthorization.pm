package Kubernetes::REST::RbacAuthorization;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'RbacAuthorization' });
1;
