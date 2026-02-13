package Kubernetes::REST::Events;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Events' });
1;
