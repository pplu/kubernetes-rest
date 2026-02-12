# Kubernetes-REST

A Perl REST Client for the Kubernetes API

## Description

Kubernetes::REST provides a simple, object-oriented interface to the Kubernetes API using IO::K8s resource classes. The IO::K8s classes know their own metadata (API version, kind, whether they're namespaced), so URL building is automatic.

## Installation

```bash
cpanm Kubernetes::REST
```

## Synopsis

```perl
use Kubernetes::REST;
use IO::K8s::Api::Core::V1::Pod;

my $api = Kubernetes::REST->new(
    server => { endpoint => 'https://kubernetes.local:6443' },
    credentials => { token => $token },
);

# List pods
my $pods = $api->list('Pod', namespace => 'default');
for my $pod ($pods->items->@*) {
    say $pod->metadata->name;
}

# Get a specific pod
my $pod = $api->get('Pod', name => 'my-pod', namespace => 'default');

# Create a pod
my $new_pod = $api->create($pod_object);

# Update a pod
my $updated = $api->update($pod);

# Delete a pod
$api->delete($pod);
```

## Custom Resource Definitions (CRDs)

Register your own CRD classes and use them with the same CRUD API:

```perl
use My::StaticWebSite;

my $api = Kubernetes::REST->new(
    kubeconfig   => "$ENV{HOME}/.kube/config",
    resource_map => {
        StaticWebSite => '+My::StaticWebSite',
    },
);

my $site = $api->new_object(StaticWebSite =>
    metadata => { name => 'my-blog', namespace => 'default' },
    spec     => { domain => 'blog.example.com', replicas => 2 },
);
my $created = $api->create($site);
```

See `Kubernetes::REST::Example` for full CRD documentation including AutoGen from cluster OpenAPI specs.

## Features

- **Simple API**: Just 5 main methods: `list()`, `get()`, `create()`, `update()`, `delete()`
- **Automatic URL building**: Uses IO::K8s class metadata to construct proper API endpoints
- **CRD support**: Use custom resource classes with the standard CRUD API
- **Short class names**: Use `'Pod'` instead of `'IO::K8s::Api::Core::V1::Pod'`
- **Type safety**: All objects are strongly typed using IO::K8s classes
- **Backwards compatibility**: Deprecated v0 API still works (with warnings)

## Links

- [CPAN](https://metacpan.org/pod/Kubernetes::REST)
- [GitHub Repository](https://github.com/pplu/kubernetes-rest)
- [Issue Tracker](https://github.com/pplu/kubernetes-rest/issues)
- [Kubernetes API Documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/)

## License

Apache 2.0

## Authors

- Torsten Raudssus (GETTY) - Current maintainer
- Jose Luis Martinez - Original author

