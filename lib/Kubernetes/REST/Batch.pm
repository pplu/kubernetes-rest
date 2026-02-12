package Kubernetes::REST::Batch;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Batch' });
1;
