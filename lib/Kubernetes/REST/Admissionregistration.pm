package Kubernetes::REST::Admissionregistration;
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Admissionregistration' });
1;
