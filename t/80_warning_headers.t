#!/usr/bin/env perl
# karr k79: the API server's Warning response headers reach the caller.
#
# Fields the server dropped (unknown field "spec.nodeIP"), deprecated APIs and
# the like come back only as `Warning: 299 - "..."` response headers, which
# the client threw away. The client attribute on_warning, a coderef, is now
# called once per Warning header value of every response that passes the
# response check - check_response, the public seam async clients use,
# included - in header order, with ($text, $context): $text the quoted part of
# a `299 - "..."` value with \" and \\ unescaped, any other value raw;
# $context the string an APIError carries ("create IO::K8s::Api::Core::V1::Pod").
# An error response delivers its warnings before the APIError is thrown.
# Without on_warning nothing is written anywhere. Kubernetes::REST::HTTPResponse
# carries the headers as an optional `headers` attribute (lowercased names, an
# arrayref of values each, in order); a response object without that method
# means no warnings and no error. LWPIO and HTTPTinyIO fill it.
#
# Everything goes through a fake transport or a fake user agent; nothing
# touches the network.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use Path::Tiny qw(path);

use HTTP::Response;
use JSON::MaybeXS ();
use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::HTTPRequest;
use Kubernetes::REST::HTTPResponse;
use Kubernetes::REST::LWPIO;
use Kubernetes::REST::HTTPTinyIO;

my $tmpdir = tempdir(CLEANUP => 1);
my $wire_json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
my $CONTEXT = 'create IO::K8s::Api::Core::V1::Pod';
my $POD = {
    apiVersion => 'v1', kind => 'Pod',
    metadata   => { name => 'p1', namespace => 'default' },
    spec       => { containers => [ { name => 'c', image => 'i' } ] },
};

# A transport that answers every request with a prepared response.
{
    package Test::K80::IO;
    use Moo;
    with 'Kubernetes::REST::Role::IO';

    has response => (is => 'rw', required => 1);

    sub call { $_[0]->response }
    sub call_streaming { die 'not used' }
}

sub response {
    my (%args) = @_;
    return Kubernetes::REST::HTTPResponse->new(
        status  => $args{status} // 201,
        content => $args{content} // $wire_json->encode($POD),
        (exists $args{headers} ? (headers => $args{headers}) : ()),
    );
}

sub api {
    my ($response, %args) = @_;
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        io          => Test::K80::IO->new(response => $response),
        resource_map_from_cluster => 0,
        %args,
    );
}

sub create_pod {
    my ($api) = @_;
    return $api->create($api->new_object(Pod => $POD));
}

# What $code writes to the process's STDERR.
sub stderr_of {
    my ($code) = @_;
    my $file = "$tmpdir/stderr." . int(rand 1e9);
    open my $saved, '>&', \*STDERR or die "dup STDERR: $!";
    open STDERR, '>', $file or die "redirect STDERR: $!";
    my $ok = eval { $code->(); 1 };
    my $err = $@;
    close STDERR;
    open STDERR, '>&', $saved or die "restore STDERR: $!";
    die $err unless $ok;
    return path($file)->slurp_raw;
}

my $FIELD = '299 - "unknown field \"spec.nodeIP\""';

subtest 'a Warning header on a create response reaches on_warning' => sub {
    my @calls;
    my $api = api(response(headers => { warning => [$FIELD] }),
        on_warning => sub { push @calls, [@_] });
    my $pod = eval { create_pod($api) };
    ok($pod, 'create still returns the object') or diag $@;
    is_deeply(\@calls, [ [ 'unknown field "spec.nodeIP"', $CONTEXT ] ],
        'one call, with the unescaped text and the context');
};

subtest 'backslashes are unescaped too' => sub {
    my @calls;
    my $api = api(response(headers => { warning => ['299 - "path C:\\\\dir and \\"q\\""'] }),
        on_warning => sub { push @calls, $_[0] });
    eval { create_pod($api) };
    is_deeply(\@calls, [ 'path C:\\dir and "q"' ], 'both escapes undone');
};

subtest 'two Warning headers: two calls, in order' => sub {
    my @calls;
    my $api = api(response(headers => { warning => [ '299 - "first"', '299 - "second"' ] }),
        on_warning => sub { push @calls, [@_] });
    eval { create_pod($api) };
    is_deeply(\@calls, [ [ 'first', $CONTEXT ], [ 'second', $CONTEXT ] ], 'first, then second');
};

subtest 'a value not in the 299 - "..." form is passed raw' => sub {
    my @calls;
    my $api = api(response(headers => { warning => ['plain text, no quotes'] }),
        on_warning => sub { push @calls, $_[0] });
    eval { create_pod($api) };
    is_deeply(\@calls, ['plain text, no quotes'], 'raw header value');
};

subtest 'a response without a Warning header does not call it' => sub {
    my @calls;
    my $api = api(response(headers => { 'content-type' => ['application/json'] }),
        on_warning => sub { push @calls, [@_] });
    eval { create_pod($api) };
    is_deeply(\@calls, [], 'no call');
};

subtest 'a 422 delivers its warnings before the APIError is thrown' => sub {
    my (@calls, $thrown_at_call);
    my $api = api(response(status => 422,
            content => '{"kind":"Status","status":"Failure","reason":"Invalid","code":422,"message":"bad"}',
            headers => { warning => ['299 - "dropped spec.nodeIP"'] }),
        on_warning => sub { push @calls, [@_] });
    my $ok = eval { create_pod($api); 1 };
    my $err = $@;
    ok(!$ok, 'create dies');
    isa_ok($err, 'Kubernetes::REST::APIError');
    is_deeply(\@calls, [ [ 'dropped spec.nodeIP', $CONTEXT ] ], 'the warning was delivered');
};

subtest 'check_response, the public seam, delivers too' => sub {
    my @calls;
    my $api = api(response(), on_warning => sub { push @calls, [@_] });
    my $res = response(status => 200, headers => { warning => [ '299 - "a"', '299 - "b"' ] });
    is($api->check_response($res, 'get Pod'), $res, 'returns the response');
    is_deeply(\@calls, [ [ 'a', 'get Pod' ], [ 'b', 'get Pod' ] ], 'both, with the caller\'s context');

    @calls = ();
    my $bad = response(status => 500, content => '{}', headers => { warning => ['299 - "c"'] });
    ok(!eval { $api->check_response($bad, 'get Pod'); 1 }, 'an error response dies');
    is_deeply(\@calls, [ [ 'c', 'get Pod' ] ], 'but its warning came first');
};

subtest 'without on_warning nothing is written and nothing changes' => sub {
    my $api = api(response(headers => { warning => [$FIELD] }));
    my $pod;
    my $stderr = stderr_of(sub { $pod = create_pod($api) });
    is($stderr, '', 'STDERR stays empty');
    ok($pod, 'create returns the object');
};

subtest 'a response without a headers method: no call, no error' => sub {
    my @calls;
    my $api = api(response(), on_warning => sub { push @calls, [@_] });
    my $double = Test::Kubernetes::Mock::Response->new(status => 200, content => '{}');
    ok(!$double->can('headers'), 'precondition: the test double has no headers');
    is($api->check_response($double, 'get Pod'), $double, 'passes the response');
    is_deeply(\@calls, [], 'no call');
};

subtest 'HTTPResponse carries headers as given' => sub {
    my $res = response(headers => { warning => [ 'a', 'b' ] });
    is_deeply(eval { $res->headers }, { warning => [ 'a', 'b' ] }, 'the hashref comes back');
    my $plain = Kubernetes::REST::HTTPResponse->new(status => 200, content => '{}');
    my $ph = eval { $plain->headers };
    ok(!$ph || !%$ph, 'optional: none without it');
};

# ---- the backends -----------------------------------------------------------

sub request {
    return Kubernetes::REST::HTTPRequest->new(
        method => 'GET', url => 'http://mock.local/api/v1/namespaces',
        headers => { Authorization => 'Bearer t' },
    );
}

subtest 'LWPIO puts every Warning header into headers' => sub {
    {
        package Test::K80::LWP;
        sub new { bless { res => $_[1] }, $_[0] }
        sub request { $_[0]{res} }
    }
    my $io = Kubernetes::REST::LWPIO->new;
    $io->{ua} = Test::K80::LWP->new(HTTP::Response->new(200, 'OK',
        [ 'Content-Type' => 'application/json', Warning => '299 - "one"', Warning => '299 - "two"' ],
        '{}'));
    my $res = $io->call(request());
    is($res->status, 200, 'status');
    is_deeply(eval { $res->headers->{warning} }, [ '299 - "one"', '299 - "two"' ],
        'both values, in order, under the lowercased name') or diag $@;

    $io->{ua} = Test::K80::LWP->new(HTTP::Response->new(200, 'OK', [ Warning => '299 - "only"' ], '{}'));
    is_deeply(eval { $io->call(request())->headers->{warning} }, [ '299 - "only"' ], 'a single value');
};

subtest 'HTTPTinyIO puts every Warning header into headers' => sub {
    {
        package Test::K80::Tiny;
        sub new { bless { res => $_[1] }, $_[0] }
        sub request { $_[0]{res} }
    }
    my $io = Kubernetes::REST::HTTPTinyIO->new;
    # HTTP::Tiny: a repeated header is an arrayref, a single one a string.
    $io->{ua} = Test::K80::Tiny->new({ status => 200, content => '{}',
        headers => { 'content-type' => 'application/json', warning => [ '299 - "one"', '299 - "two"' ] } });
    my $res = $io->call(request());
    is($res->status, 200, 'status');
    is_deeply(eval { $res->headers->{warning} }, [ '299 - "one"', '299 - "two"' ],
        'repeated header: both values, in order') or diag $@;

    $io->{ua} = Test::K80::Tiny->new({ status => 200, content => '{}',
        headers => { warning => '299 - "only"' } });
    is_deeply(eval { $io->call(request())->headers->{warning} }, [ '299 - "only"' ],
        'single header: one value in an arrayref');
};

done_testing;
