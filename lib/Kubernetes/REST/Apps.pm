package Kubernetes::REST::Apps;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Apps' });
1;
