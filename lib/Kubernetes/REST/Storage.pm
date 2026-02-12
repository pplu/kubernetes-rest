package Kubernetes::REST::Storage;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Storage' });
1;
