#!/usr/bin/env perl
# Tests the full CRUD cycle from Kubernetes::REST::Example against
# mock fixtures (no live cluster needed) or live cluster when available.

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api live_api is_live);
use MIME::Base64 qw(encode_base64);

my $api;
if (is_live()) {
    diag "Running against LIVE cluster: $ENV{TEST_KUBERNETES_REST_KUBECONFIG}";
    $api = eval { live_api() };
    if ($@) {
        plan skip_all => "No cluster available: $@";
    }
} else {
    diag "Running with MOCK responses";
    $api = mock_api();
}

# Clean up from previous runs (live only)
if (is_live()) {
    diag "Cleaning up perl-test namespace from previous run (if exists)...";
    eval { $api->delete('Namespace', 'perl-test') };
    if (!$@) {
        # Wait for namespace to be fully deleted
        for (1..30) {
            my $ns = eval { $api->get('Namespace', 'perl-test') };
            last unless $ns;
            sleep 1;
        }
    }
}

# === 1. Create Namespace ===
subtest 'create Namespace' => sub {
    my $ns = $api->new_object(Namespace =>
        metadata => { name => 'perl-test' },
    );
    ok($ns, 'new_object works');
    is($ns->kind, 'Namespace', 'kind');

    my $created = eval { $api->create($ns) };
    if (!$created && is_live()) {
        # Namespace may already exist from a previous test run
        diag "Namespace already exists, fetching instead";
        $created = $api->get('Namespace', 'perl-test');
    }
    ok($created, 'create returns object');
    is($created->metadata->name, 'perl-test', 'name matches');
    ok($created->metadata->uid, 'has uid from server');
    ok($created->metadata->creationTimestamp, 'has creationTimestamp');
};

# === 2. Create ConfigMap ===
subtest 'create ConfigMap' => sub {
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
    my $created = $api->create($cm);
    ok($created, 'ConfigMap created');
    is($created->metadata->name, 'app-config', 'name');
    is($created->kind, 'ConfigMap', 'kind');
    is($created->data->{'database.host'}, 'postgres.perl-test.svc.cluster.local', 'data preserved');
};

# === 3. Create Secret ===
subtest 'create Secret' => sub {
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
    my $created = $api->create($secret);
    ok($created, 'Secret created');
    is($created->metadata->name, 'db-credentials', 'name');
    is($created->type, 'Opaque', 'type');
};

# === 4. Create LimitRange ===
subtest 'create LimitRange' => sub {
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
    my $created = $api->create($lr);
    ok($created, 'LimitRange created');
    is($created->metadata->name, 'default-limits', 'name');
    is($created->kind, 'LimitRange', 'kind');
};

# === 5. Create Deployment ===
subtest 'create Deployment' => sub {
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
                    labels => { app => 'my-app' },
                },
                spec => {
                    containers => [{
                        name  => 'nginx',
                        image => 'nginx:1.27-alpine',
                        ports => [{ containerPort => 80 }],
                    }],
                },
            },
        },
    );
    my $created = $api->create($deploy);
    ok($created, 'Deployment created');
    is($created->metadata->name, 'my-app', 'name');
    is($created->kind, 'Deployment', 'kind');
    is($created->api_version, 'apps/v1', 'apiVersion');
    is($created->spec->replicas, 2, 'replicas');
};

# === 6. Get Deployment ===
subtest 'get Deployment' => sub {
    my $deploy = $api->get('Deployment', 'my-app', namespace => 'perl-test');
    ok($deploy, 'get returns object');
    is($deploy->metadata->name, 'my-app', 'name');
    is($deploy->kind, 'Deployment', 'kind');
    ok(defined $deploy->status, 'has status from server');
};

# === 7. Update Deployment (scale) ===
subtest 'update Deployment' => sub {
    # Retry loop: Kubernetes controllers may mutate the deployment between
    # get and update (e.g. LimitRange injecting defaults), causing a 409 Conflict.
    my $updated;
    for my $attempt (1..3) {
        my $deploy = $api->get('Deployment', 'my-app', namespace => 'perl-test');
        $deploy->spec->replicas(3);
        $updated = eval { $api->update($deploy) };
        last if $updated;
        diag "Update attempt $attempt failed (409 conflict), retrying..." if $attempt < 3;
        sleep 1 if is_live();
    }
    ok($updated, 'update returns object');
    is($updated->spec->replicas, 3, 'replicas updated');
};

# === 8. Create Service ===
subtest 'create Service' => sub {
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
    my $created = $api->create($svc);
    ok($created, 'Service created');
    is($created->metadata->name, 'my-app', 'name');
    is($created->spec->type, 'NodePort', 'type');
    ok($created->spec->ports->[0]->nodePort, 'has nodePort from server');
};

# === 9. Create Job ===
subtest 'create Job' => sub {
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
    my $created = $api->create($job);
    ok($created, 'Job created');
    is($created->metadata->name, 'batch-job', 'name');
    is($created->kind, 'Job', 'kind');
    is($created->api_version, 'batch/v1', 'apiVersion');
};

# === 10. Create CronJob ===
subtest 'create CronJob' => sub {
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
    my $created = $api->create($cron);
    ok($created, 'CronJob created');
    is($created->metadata->name, 'scheduled-job', 'name');
    is($created->spec->schedule, '*/5 * * * *', 'schedule');
};

# === 11. Create Role (RBAC) ===
subtest 'create Role' => sub {
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
    my $created = $api->create($role);
    ok($created, 'Role created');
    is($created->metadata->name, 'pod-reader', 'name');
    is($created->kind, 'Role', 'kind');
    is($created->api_version, 'rbac.authorization.k8s.io/v1', 'apiVersion');
};

# === 12. Create RoleBinding (RBAC) ===
subtest 'create RoleBinding' => sub {
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
    my $created = $api->create($binding);
    ok($created, 'RoleBinding created');
    is($created->metadata->name, 'read-pods', 'name');
    is($created->roleRef->name, 'pod-reader', 'roleRef');
};

# === 13. Create PVC ===
subtest 'create PersistentVolumeClaim' => sub {
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
    my $created = $api->create($pvc);
    ok($created, 'PVC created');
    is($created->metadata->name, 'my-storage', 'name');
    is($created->kind, 'PersistentVolumeClaim', 'kind');
};

# === 14. Create ResourceQuota ===
subtest 'create ResourceQuota' => sub {
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
    my $created = $api->create($quota);
    ok($created, 'ResourceQuota created');
    is($created->metadata->name, 'ns-quota', 'name');
};

# === 15. Get ResourceQuota (with status) ===
subtest 'get ResourceQuota with usage' => sub {
    # Kubernetes needs time to compute quota status after creation
    my $q;
    for my $attempt (1..10) {
        $q = $api->get('ResourceQuota', 'ns-quota', namespace => 'perl-test');
        last if $q && $q->status && $q->status->hard;
        sleep 1 if is_live();
    }
    ok($q, 'got quota');
    ok($q->status, 'has status');
    ok($q->status->hard, 'has hard limits');
    ok($q->status->used, 'has usage data');
    my $hard = $q->status->hard;
    my $used = $q->status->used;
    ok(exists $hard->{pods}, 'hard has pods');
    ok(exists $used->{pods}, 'used has pods');
};

# === 16. Delete operations ===
subtest 'delete CronJob' => sub {
    ok($api->delete('CronJob', 'scheduled-job', namespace => 'perl-test'),
        'CronJob deleted');
};

subtest 'delete Job' => sub {
    ok($api->delete('Job', 'batch-job', namespace => 'perl-test'),
        'Job deleted');
};

subtest 'delete Service' => sub {
    ok($api->delete('Service', 'my-app', namespace => 'perl-test'),
        'Service deleted');
};

subtest 'delete Deployment' => sub {
    ok($api->delete('Deployment', 'my-app', namespace => 'perl-test'),
        'Deployment deleted');
};

subtest 'delete Namespace' => sub {
    ok($api->delete('Namespace', 'perl-test'),
        'Namespace deleted');
};

# === 17. Serialization roundtrip ===
subtest 'serialization roundtrip' => sub {
    my $deploy = $api->new_object(Deployment =>
        metadata => {
            name      => 'roundtrip',
            namespace => 'default',
        },
        spec => {
            replicas => 5,
            selector => { matchLabels => { app => 'rt' } },
            template => {
                metadata => { labels => { app => 'rt' } },
                spec => {
                    containers => [{
                        name => 'test', image => 'busybox',
                    }],
                },
            },
        },
    );

    # TO_JSON -> inflate roundtrip
    my $data = $deploy->TO_JSON;
    is($data->{kind}, 'Deployment', 'TO_JSON kind');
    is($data->{apiVersion}, 'apps/v1', 'TO_JSON apiVersion');

    my $rt = $api->inflate($data);
    is($rt->metadata->name, 'roundtrip', 'roundtrip name');
    is($rt->spec->replicas, 5, 'roundtrip replicas');
    is($rt->kind, 'Deployment', 'roundtrip kind');

    # YAML roundtrip
    my $yaml = $deploy->to_yaml;
    like($yaml, qr/kind:\s*Deployment/, 'YAML has kind');
    like($yaml, qr/replicas:\s*5/, 'YAML has replicas');
};

done_testing;
