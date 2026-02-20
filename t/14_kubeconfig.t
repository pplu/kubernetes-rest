#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempfile tempdir);
use YAML::XS ();
use MIME::Base64 qw(encode_base64 decode_base64);

use_ok('Kubernetes::REST::Kubeconfig');

# ============================================================================
# Create fixture kubeconfig files
# ============================================================================

my $tmpdir = tempdir(CLEANUP => 1);

# Write a CA file for testing file references
my $ca_file = "$tmpdir/ca.crt";
open my $fh, '>', $ca_file or die "Cannot write $ca_file: $!";
print $fh "-----BEGIN CERTIFICATE-----\nFAKECA\n-----END CERTIFICATE-----\n";
close $fh;

my $cert_file = "$tmpdir/client.crt";
open $fh, '>', $cert_file or die "Cannot write $cert_file: $!";
print $fh "-----BEGIN CERTIFICATE-----\nFAKECERT\n-----END CERTIFICATE-----\n";
close $fh;

my $key_file = "$tmpdir/client.key";
open $fh, '>', $key_file or die "Cannot write $key_file: $!";
print $fh "-----BEGIN RSA PRIVATE KEY-----\nFAKEKEY\n-----END RSA PRIVATE KEY-----\n";
close $fh;

# Base64-encoded cert data (for inline certs)
my $ca_data = encode_base64("FAKE-CA-CERT-DATA", "");
my $cert_data = encode_base64("FAKE-CLIENT-CERT-DATA", "");
my $key_data = encode_base64("FAKE-CLIENT-KEY-DATA", "");

my $kubeconfig = {
    apiVersion => 'v1',
    kind => 'Config',
    'current-context' => 'production',
    clusters => [
        {
            name => 'prod-cluster',
            cluster => {
                server => 'https://prod.k8s.local:6443',
                'certificate-authority' => $ca_file,
            },
        },
        {
            name => 'dev-cluster',
            cluster => {
                server => 'https://dev.k8s.local:6443',
                'certificate-authority-data' => $ca_data,
            },
        },
        {
            name => 'insecure-cluster',
            cluster => {
                server => 'https://insecure.k8s.local:6443',
                'insecure-skip-tls-verify' => 1,
            },
        },
    ],
    contexts => [
        {
            name => 'production',
            context => {
                cluster => 'prod-cluster',
                user => 'token-user',
                namespace => 'prod',
            },
        },
        {
            name => 'development',
            context => {
                cluster => 'dev-cluster',
                user => 'cert-user',
                namespace => 'dev',
            },
        },
        {
            name => 'insecure',
            context => {
                cluster => 'insecure-cluster',
                user => 'no-auth-user',
            },
        },
    ],
    users => [
        {
            name => 'token-user',
            user => {
                token => 'my-secret-token-12345',
            },
        },
        {
            name => 'cert-user',
            user => {
                'client-certificate' => $cert_file,
                'client-key' => $key_file,
            },
        },
        {
            name => 'cert-data-user',
            user => {
                'client-certificate-data' => $cert_data,
                'client-key-data' => $key_data,
            },
        },
        {
            name => 'no-auth-user',
            user => {},
        },
    ],
};

my $config_file = "$tmpdir/kubeconfig";
YAML::XS::DumpFile($config_file, $kubeconfig);

# ============================================================================
# Tests
# ============================================================================

subtest 'construction' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    ok $kc, 'Kubeconfig created';
    is $kc->kubeconfig_path, $config_file, 'kubeconfig_path set';
};

subtest 'current_context_name - default' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    is $kc->current_context_name, 'production', 'default context is production';
};

subtest 'current_context_name - override' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => $config_file,
        context_name => 'development',
    );
    is $kc->current_context_name, 'development', 'context overridden to development';
};

subtest 'contexts - list all' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    my $contexts = $kc->contexts;
    is ref $contexts, 'ARRAY', 'contexts returns arrayref';
    is scalar @$contexts, 3, 'three contexts';
    is_deeply [sort @$contexts], ['development', 'insecure', 'production'],
        'correct context names';
};

subtest 'context - lookup by name' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    my $ctx = $kc->context('production');
    is $ctx->{cluster}, 'prod-cluster', 'production context cluster';
    is $ctx->{user}, 'token-user', 'production context user';
    is $ctx->{namespace}, 'prod', 'production context namespace';
};

subtest 'context - defaults to current context' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    my $ctx = $kc->context;
    is $ctx->{cluster}, 'prod-cluster', 'default context is production cluster';
};

subtest 'context - not found' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    throws_ok { $kc->context('nonexistent') } qr/Context not found: nonexistent/,
        'throws for unknown context';
};

subtest 'cluster - lookup by name' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    my $cluster = $kc->cluster('prod-cluster');
    is $cluster->{server}, 'https://prod.k8s.local:6443', 'cluster server endpoint';
    is $cluster->{'certificate-authority'}, $ca_file, 'cluster CA file';
};

subtest 'cluster - not found' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    throws_ok { $kc->cluster('nonexistent') } qr/Cluster not found/,
        'throws for unknown cluster';
};

subtest 'user - token user' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    my $user = $kc->user('token-user');
    is $user->{token}, 'my-secret-token-12345', 'token retrieved';
};

subtest 'user - cert user' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    my $user = $kc->user('cert-user');
    is $user->{'client-certificate'}, $cert_file, 'cert file path';
    is $user->{'client-key'}, $key_file, 'key file path';
};

subtest 'user - not found' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    throws_ok { $kc->user('nonexistent') } qr/User not found/,
        'throws for unknown user';
};

subtest 'api - token auth with CA file' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    my $api = $kc->api('production');
    isa_ok $api, 'Kubernetes::REST';
    is $api->server->endpoint, 'https://prod.k8s.local:6443', 'server endpoint';
    is $api->server->ssl_verify_server, 1, 'SSL verification enabled';
    is $api->server->ssl_ca_file, $ca_file, 'CA file set';
    is $api->credentials->token, 'my-secret-token-12345', 'token set';
};

subtest 'api - cert auth with cert file references' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    my $api = $kc->api('development');
    isa_ok $api, 'Kubernetes::REST';
    is $api->server->endpoint, 'https://dev.k8s.local:6443', 'dev server endpoint';
    is $api->server->ssl_cert_file, $cert_file, 'client cert file set';
    is $api->server->ssl_key_file, $key_file, 'client key file set';
    # CA from base64 data should be in-memory PEM, not a file
    ok $api->server->ssl_ca_pem, 'CA PEM data set (from base64 data)';
    ok !$api->server->ssl_ca_file, 'no CA file (in-memory instead)';
};

subtest 'api - insecure skip TLS verify' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    my $api = $kc->api('insecure');
    is $api->server->ssl_verify_server, 0, 'SSL verification disabled';
    # No auth user should get empty token
    is $api->credentials->token, '', 'empty token for no-auth user';
};

subtest 'api - default context' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
    my $api = $kc->api;
    is $api->server->endpoint, 'https://prod.k8s.local:6443',
        'api() without args uses current-context';
};

subtest 'api - with context_name constructor arg' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => $config_file,
        context_name => 'development',
    );
    my $api = $kc->api;
    is $api->server->endpoint, 'https://dev.k8s.local:6443',
        'api() uses context_name from constructor';
};

subtest 'missing kubeconfig file' => sub {
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => '/nonexistent/kubeconfig',
    );
    throws_ok { $kc->contexts } qr/Kubeconfig not found/,
        'throws for missing kubeconfig file';
};

subtest 'in-memory PEM survives kubeconfig destruction' => sub {
    my $api;
    {
        my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config_file);
        $api = $kc->api('development');
    }
    # After $kc goes out of scope, PEM data lives in the API server object
    ok $api->server->ssl_ca_pem, 'CA PEM still available after kubeconfig destroyed';
    is $api->server->ssl_ca_pem, decode_base64($ca_data), 'PEM data matches original';
};

subtest 'inline cert-data uses PEM attributes, file refs use file attributes' => sub {
    # Add a context that uses inline cert-data for user creds
    my $inline_config = {
        %$kubeconfig,
        contexts => [
            @{$kubeconfig->{contexts}},
            {
                name => 'inline-certs',
                context => {
                    cluster => 'dev-cluster',
                    user => 'cert-data-user',
                },
            },
        ],
    };
    my $inline_file = "$tmpdir/kubeconfig-inline";
    YAML::XS::DumpFile($inline_file, $inline_config);

    my $kc = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $inline_file);
    my $api = $kc->api('inline-certs');

    # User has inline cert-data → PEM attributes
    ok $api->server->ssl_cert_pem, 'client cert is PEM (from inline data)';
    ok $api->server->ssl_key_pem, 'client key is PEM (from inline data)';
    ok !$api->server->ssl_cert_file, 'no cert file (in-memory)';
    ok !$api->server->ssl_key_file, 'no key file (in-memory)';

    # Cluster has inline CA data → PEM
    ok $api->server->ssl_ca_pem, 'CA is PEM (from inline data)';
    ok !$api->server->ssl_ca_file, 'no CA file (in-memory)';

    # File-based context still uses file attributes
    my $api2 = $kc->api('production');
    is $api2->server->ssl_ca_file, $ca_file, 'file-based CA uses ssl_ca_file';
    ok !$api2->server->ssl_ca_pem, 'no PEM for file-based CA';
};

done_testing;
