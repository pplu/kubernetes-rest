package Kubernetes::REST::Autoscaling;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Autoscaling' });
1;
