package Kubernetes::REST::Core;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Core' });
1;
