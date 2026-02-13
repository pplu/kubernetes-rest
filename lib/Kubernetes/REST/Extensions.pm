package Kubernetes::REST::Extensions;
# ABSTRACT: DEPRECATED - v0 compatibility stub
use strict;
use warnings;
warn __PACKAGE__ . " is deprecated, use the new Kubernetes::REST API instead";

=head1 DESCRIPTION

B<This module is DEPRECATED>. Use L<Kubernetes::REST> directly instead.

The Extensions API group was removed from Kubernetes. Use the appropriate replacement APIs (Apps, Networking, Policy, etc.).

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=cut

1;
