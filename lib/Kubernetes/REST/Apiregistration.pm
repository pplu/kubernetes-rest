package Kubernetes::REST::Apiregistration;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Apiregistration' });
1;
