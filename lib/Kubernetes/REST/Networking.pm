package Kubernetes::REST::Networking;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Networking' });
1;
