package Kubernetes::REST::Authentication;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Authentication' });
1;
