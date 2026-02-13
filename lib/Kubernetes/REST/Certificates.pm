package Kubernetes::REST::Certificates;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Certificates' });
1;
