package My::StaticWebSite;
# Example CRD class for a homelab StaticWebSite custom resource.
# Demonstrates how to write a hand-written CRD class for use with
# Kubernetes::REST.

use IO::K8s::APIObject
    api_version     => 'homelab.example.com/v1',
    resource_plural => 'staticwebsites';

with 'IO::K8s::Role::Namespaced';

# CRD spec fields
k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;
