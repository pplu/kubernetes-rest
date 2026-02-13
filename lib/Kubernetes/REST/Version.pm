package Kubernetes::REST::Version;
our $VERSION = '1.001';
# ABSTRACT: DEPRECATED - v0 compatibility stub
use strict;
use warnings;
warn __PACKAGE__ . " is deprecated, use the new Kubernetes::REST API instead";

=head1 DESCRIPTION

B<This module is DEPRECATED>. Use L<Kubernetes::REST> directly instead.

For cluster version information, use C<< $api->cluster_version >>.

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=cut

1;
