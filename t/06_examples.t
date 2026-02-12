#!/usr/bin/env perl
# Tests that all code examples from Kubernetes::REST::Example POD
# construct valid IO::K8s objects (no live cluster needed).

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Kubernetes::REST;
use MIME::Base64 qw(encode_base64);

# Create a Kubernetes::REST instance for new_object (no server needed)
my $api = Kubernetes::REST->new(
    server => {
        endpoint          => 'https://127.0.0.1:6443',
        ssl_verify_server => 0,
    },
    credentials              => { token => 'test' },
    resource_map_from_cluster => 0,
);

ok($api, 'API object created');

# === Namespace ===
subtest 'Example: Namespace' => sub {
    my $ns = $api->new_object(Namespace =>
        metadata => { name => 'perl-test' },
    );
    ok($ns, 'Namespace created');
    is($ns->metadata->name, 'perl-test', 'name');
    is($ns->kind, 'Namespace', 'kind');
    is($ns->api_version, 'v1', 'apiVersion');
};

# === ConfigMap ===
subtest 'Example: ConfigMap' => sub {
    my $cm = $api->new_object(ConfigMap =>
        metadata => {
            name      => 'app-config',
            namespace => 'perl-test',
        },
        data => {
            'database.host' => 'postgres.perl-test.svc.cluster.local',
            'database.port' => '5432',
            'app.debug'     => 'true',
        },
    );
    ok($cm, 'ConfigMap created');
    is($cm->metadata->name, 'app-config', 'name');
    is($cm->metadata->namespace, 'perl-test', 'namespace');
    is($cm->data->{'database.host'}, 'postgres.perl-test.svc.cluster.local', 'data key');
    is($cm->kind, 'ConfigMap', 'kind');
    is($cm->api_version, 'v1', 'apiVersion');
};

# === Secret ===
subtest 'Example: Secret' => sub {
    my $secret = $api->new_object(Secret =>
        metadata => {
            name      => 'db-credentials',
            namespace => 'perl-test',
        },
        type => 'Opaque',
        data => {
            username => encode_base64('admin', ''),
            password => encode_base64('s3cret', ''),
        },
    );
    ok($secret, 'Secret created');
    is($secret->metadata->name, 'db-credentials', 'name');
    is($secret->type, 'Opaque', 'type');
    is($secret->data->{username}, encode_base64('admin', ''), 'data.username');
    is($secret->kind, 'Secret', 'kind');
};

# === LimitRange ===
subtest 'Example: LimitRange' => sub {
    my $lr = $api->new_object(LimitRange =>
        metadata => {
            name      => 'default-limits',
            namespace => 'perl-test',
        },
        spec => {
            limits => [{
                type => 'Container',
                default        => { cpu => '200m', memory => '128Mi' },
                defaultRequest => { cpu => '50m',  memory => '64Mi' },
            }],
        },
    );
    ok($lr, 'LimitRange created');
    is($lr->metadata->name, 'default-limits', 'name');
    is($lr->kind, 'LimitRange', 'kind');
    is($lr->api_version, 'v1', 'apiVersion');
    ok($lr->spec, 'has spec');
    ok($lr->spec->limits, 'has limits');
    is(scalar @{$lr->spec->limits}, 1, 'one limit entry');
    is($lr->spec->limits->[0]->type, 'Container', 'limit type');
};

# === Deployment with volumes, probes, and env ===
subtest 'Example: Deployment' => sub {
    my $deploy = $api->new_object(Deployment =>
        metadata => {
            name      => 'my-app',
            namespace => 'perl-test',
        },
        spec => {
            replicas => 2,
            selector => {
                matchLabels => { app => 'my-app' },
            },
            template => {
                metadata => {
                    labels      => { app => 'my-app' },
                    annotations => { 'managed-by' => 'perl' },
                },
                spec => {
                    serviceAccountName => 'default',
                    containers => [{
                        name  => 'nginx',
                        image => 'nginx:1.27-alpine',
                        ports => [{ containerPort => 80, name => 'http' }],
                        env => [{
                            name => 'APP_ENV',
                            valueFrom => {
                                configMapKeyRef => {
                                    name => 'app-config',
                                    key  => 'app.debug',
                                },
                            },
                        }, {
                            name => 'DB_USER',
                            valueFrom => {
                                secretKeyRef => {
                                    name => 'db-credentials',
                                    key  => 'username',
                                },
                            },
                        }],
                        volumeMounts => [{
                            name      => 'config-volume',
                            mountPath => '/etc/nginx/conf.d',
                        }, {
                            name      => 'data-volume',
                            mountPath => '/data',
                        }],
                        resources => {
                            requests => { cpu => '50m',  memory => '32Mi' },
                            limits   => { cpu => '100m', memory => '64Mi' },
                        },
                        livenessProbe => {
                            httpGet => { path => '/', port => 80 },
                            initialDelaySeconds => 5,
                            periodSeconds => 10,
                        },
                        readinessProbe => {
                            httpGet => { path => '/', port => 80 },
                            initialDelaySeconds => 3,
                            periodSeconds => 5,
                        },
                    }],
                    volumes => [{
                        name => 'config-volume',
                        configMap => {
                            name  => 'app-config',
                            items => [{
                                key  => 'nginx.conf',
                                path => 'default.conf',
                            }],
                        },
                    }, {
                        name => 'data-volume',
                        persistentVolumeClaim => {
                            claimName => 'my-storage',
                        },
                    }],
                },
            },
        },
    );
    ok($deploy, 'Deployment created');
    is($deploy->metadata->name, 'my-app', 'name');
    is($deploy->kind, 'Deployment', 'kind');
    is($deploy->api_version, 'apps/v1', 'apiVersion');
    is($deploy->spec->replicas, 2, 'replicas');

    # Template
    my $tmpl = $deploy->spec->template;
    ok($tmpl, 'has template');
    is($tmpl->metadata->labels->{app}, 'my-app', 'template labels');
    is($tmpl->metadata->annotations->{'managed-by'}, 'perl', 'template annotations');
    is($tmpl->spec->serviceAccountName, 'default', 'serviceAccountName');

    # Container
    my $c = $tmpl->spec->containers->[0];
    is($c->name, 'nginx', 'container name');
    is($c->image, 'nginx:1.27-alpine', 'container image');
    is(scalar @{$c->ports}, 1, 'one port');
    is($c->ports->[0]->containerPort, 80, 'container port');

    # Env
    is(scalar @{$c->env}, 2, 'two env vars');
    is($c->env->[0]->name, 'APP_ENV', 'env[0] name');
    ok($c->env->[0]->valueFrom->configMapKeyRef, 'env from configMap');
    is($c->env->[1]->name, 'DB_USER', 'env[1] name');
    ok($c->env->[1]->valueFrom->secretKeyRef, 'env from secret');

    # Volume mounts
    is(scalar @{$c->volumeMounts}, 2, 'two volume mounts');
    is($c->volumeMounts->[0]->name, 'config-volume', 'volumeMount[0] name');
    is($c->volumeMounts->[0]->mountPath, '/etc/nginx/conf.d', 'volumeMount[0] path');

    # Resources
    ok($c->resources, 'has resources');
    is($c->resources->requests->{cpu}, '50m', 'cpu request');

    # Probes
    ok($c->livenessProbe, 'has liveness probe');
    is($c->livenessProbe->httpGet->path, '/', 'liveness path');
    ok($c->readinessProbe, 'has readiness probe');
    is($c->readinessProbe->periodSeconds, 5, 'readiness period');

    # Volumes
    my $vols = $tmpl->spec->volumes;
    is(scalar @$vols, 2, 'two volumes');
    is($vols->[0]->name, 'config-volume', 'volume[0] name');
    ok($vols->[0]->configMap, 'volume from configMap');
    is($vols->[1]->name, 'data-volume', 'volume[1] name');
    ok($vols->[1]->persistentVolumeClaim, 'volume from PVC');

    # Serialization roundtrip
    my $json_data = $deploy->TO_JSON;
    is($json_data->{apiVersion}, 'apps/v1', 'TO_JSON apiVersion');
    is($json_data->{kind}, 'Deployment', 'TO_JSON kind');
    my $rt = $api->inflate($json_data);
    is($rt->metadata->name, 'my-app', 'roundtrip name');
    is($rt->spec->replicas, 2, 'roundtrip replicas');
};

# === Service (NodePort) ===
subtest 'Example: Service' => sub {
    my $svc = $api->new_object(Service =>
        metadata => {
            name      => 'my-app',
            namespace => 'perl-test',
        },
        spec => {
            type     => 'NodePort',
            selector => { app => 'my-app' },
            ports    => [{
                port       => 80,
                targetPort => 80,
                protocol   => 'TCP',
            }],
        },
    );
    ok($svc, 'Service created');
    is($svc->metadata->name, 'my-app', 'name');
    is($svc->kind, 'Service', 'kind');
    is($svc->api_version, 'v1', 'apiVersion');
    is($svc->spec->type, 'NodePort', 'type');
    is(scalar @{$svc->spec->ports}, 1, 'one port');
    is($svc->spec->ports->[0]->port, 80, 'port number');
    is($svc->spec->ports->[0]->protocol, 'TCP', 'protocol');
};

# === Job ===
subtest 'Example: Job' => sub {
    my $job = $api->new_object(Job =>
        metadata => {
            name      => 'batch-job',
            namespace => 'perl-test',
        },
        spec => {
            backoffLimit => 2,
            template => {
                spec => {
                    restartPolicy => 'Never',
                    containers => [{
                        name    => 'worker',
                        image   => 'busybox:latest',
                        command => ['sh', '-c', 'echo "done"; exit 0'],
                    }],
                },
            },
        },
    );
    ok($job, 'Job created');
    is($job->metadata->name, 'batch-job', 'name');
    is($job->kind, 'Job', 'kind');
    is($job->api_version, 'batch/v1', 'apiVersion');
    is($job->spec->backoffLimit, 2, 'backoffLimit');
    is($job->spec->template->spec->restartPolicy, 'Never', 'restartPolicy');
    is($job->spec->template->spec->containers->[0]->name, 'worker', 'container name');
};

# === CronJob ===
subtest 'Example: CronJob' => sub {
    my $cron = $api->new_object(CronJob =>
        metadata => {
            name      => 'scheduled-job',
            namespace => 'perl-test',
        },
        spec => {
            schedule => '*/5 * * * *',
            jobTemplate => {
                spec => {
                    template => {
                        spec => {
                            restartPolicy => 'OnFailure',
                            containers => [{
                                name    => 'worker',
                                image   => 'busybox:latest',
                                command => ['sh', '-c', 'date'],
                            }],
                        },
                    },
                },
            },
        },
    );
    ok($cron, 'CronJob created');
    is($cron->metadata->name, 'scheduled-job', 'name');
    is($cron->kind, 'CronJob', 'kind');
    is($cron->api_version, 'batch/v1', 'apiVersion');
    is($cron->spec->schedule, '*/5 * * * *', 'schedule');
    my $inner = $cron->spec->jobTemplate->spec->template->spec;
    is($inner->restartPolicy, 'OnFailure', 'inner restartPolicy');
    is($inner->containers->[0]->name, 'worker', 'inner container name');
};

# === RBAC Role ===
subtest 'Example: Role' => sub {
    my $role = $api->new_object(Role =>
        metadata => {
            name      => 'pod-reader',
            namespace => 'perl-test',
        },
        rules => [{
            apiGroups => [''],
            resources => ['pods'],
            verbs     => ['get', 'list', 'watch'],
        }],
    );
    ok($role, 'Role created');
    is($role->metadata->name, 'pod-reader', 'name');
    is($role->kind, 'Role', 'kind');
    is($role->api_version, 'rbac.authorization.k8s.io/v1', 'apiVersion');
    is(scalar @{$role->rules}, 1, 'one rule');
    is_deeply($role->rules->[0]->verbs, ['get', 'list', 'watch'], 'verbs');
    is_deeply($role->rules->[0]->resources, ['pods'], 'resources');
};

# === RBAC RoleBinding ===
subtest 'Example: RoleBinding' => sub {
    my $binding = $api->new_object(RoleBinding =>
        metadata => {
            name      => 'read-pods',
            namespace => 'perl-test',
        },
        roleRef => {
            apiGroup => 'rbac.authorization.k8s.io',
            kind     => 'Role',
            name     => 'pod-reader',
        },
        subjects => [{
            kind      => 'ServiceAccount',
            name      => 'default',
            namespace => 'perl-test',
        }],
    );
    ok($binding, 'RoleBinding created');
    is($binding->metadata->name, 'read-pods', 'name');
    is($binding->kind, 'RoleBinding', 'kind');
    is($binding->api_version, 'rbac.authorization.k8s.io/v1', 'apiVersion');
    is($binding->roleRef->kind, 'Role', 'roleRef kind');
    is($binding->roleRef->name, 'pod-reader', 'roleRef name');
    is(scalar @{$binding->subjects}, 1, 'one subject');
    is($binding->subjects->[0]->name, 'default', 'subject name');
};

# === PersistentVolumeClaim ===
subtest 'Example: PersistentVolumeClaim' => sub {
    my $pvc = $api->new_object(PersistentVolumeClaim =>
        metadata => {
            name      => 'my-storage',
            namespace => 'perl-test',
        },
        spec => {
            accessModes => ['ReadWriteOnce'],
            resources => {
                requests => { storage => '100Mi' },
            },
        },
    );
    ok($pvc, 'PersistentVolumeClaim created');
    is($pvc->metadata->name, 'my-storage', 'name');
    is($pvc->kind, 'PersistentVolumeClaim', 'kind');
    is($pvc->api_version, 'v1', 'apiVersion');
    is_deeply($pvc->spec->accessModes, ['ReadWriteOnce'], 'accessModes');
    is($pvc->spec->resources->requests->{storage}, '100Mi', 'storage request');
};

# === ResourceQuota ===
subtest 'Example: ResourceQuota' => sub {
    my $quota = $api->new_object(ResourceQuota =>
        metadata => {
            name      => 'ns-quota',
            namespace => 'perl-test',
        },
        spec => {
            hard => {
                pods               => '20',
                'requests.cpu'     => '2',
                'requests.memory'  => '1Gi',
            },
        },
    );
    ok($quota, 'ResourceQuota created');
    is($quota->metadata->name, 'ns-quota', 'name');
    is($quota->kind, 'ResourceQuota', 'kind');
    is($quota->api_version, 'v1', 'apiVersion');
    is($quota->spec->hard->{pods}, '20', 'hard.pods');
    is($quota->spec->hard->{'requests.cpu'}, '2', 'hard.requests.cpu');
};

# === YAML serialization ===
subtest 'Example: YAML serialization' => sub {
    my $ns = $api->new_object(Namespace =>
        metadata => { name => 'yaml-test' },
    );
    my $yaml = $ns->to_yaml;
    ok($yaml, 'to_yaml works');
    like($yaml, qr/kind:\s*Namespace/, 'YAML contains kind');
    like($yaml, qr/name:\s*yaml-test/, 'YAML contains name');
    like($yaml, qr/apiVersion:\s*v1/, 'YAML contains apiVersion');
};

# === JSON serialization roundtrip ===
subtest 'Example: JSON roundtrip' => sub {
    my $svc = $api->new_object(Service =>
        metadata => {
            name      => 'roundtrip-svc',
            namespace => 'default',
        },
        spec => {
            type     => 'ClusterIP',
            selector => { app => 'test' },
            ports    => [{ port => 80, protocol => 'TCP' }],
        },
    );

    my $json_data = $svc->TO_JSON;
    ok($json_data, 'TO_JSON returns data');
    is($json_data->{kind}, 'Service', 'kind in JSON');

    my $rt = $api->inflate($json_data);
    ok($rt, 'inflate works');
    is($rt->metadata->name, 'roundtrip-svc', 'roundtrip name');
    is($rt->spec->type, 'ClusterIP', 'roundtrip type');
    is($rt->spec->ports->[0]->port, 80, 'roundtrip port');
};

done_testing;
