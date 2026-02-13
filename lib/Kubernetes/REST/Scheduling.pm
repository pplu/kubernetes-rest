package Kubernetes::REST::Scheduling;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Scheduling' });
1;
