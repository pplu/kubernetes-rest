package Kubernetes::REST::Result2Hash;
# ABSTRACT: DEPRECATED - v0 compatibility stub
use strict;
use warnings;
warn __PACKAGE__ . " is deprecated, use the new Kubernetes::REST API instead";

=head1 DESCRIPTION

B<This module is DEPRECATED>. Use L<Kubernetes::REST> directly instead.

The new API returns typed L<IO::K8s> objects. Use C<< $object->TO_JSON >> to convert to hashref.

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=cut

1;
