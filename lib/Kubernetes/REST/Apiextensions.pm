package Kubernetes::REST::Apiextensions;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Apiextensions' });
1;
