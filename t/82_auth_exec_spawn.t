#!/usr/bin/env perl
# Windows has no forking pipe open, so AuthExec runs the plugin there through
# _run_plugin_spawn: system {$cmd} $cmd, @args with STDOUT redirected to a
# temporary file. The method works on every platform, so this suite runs it
# here too, on top of what t/71 and t/75 hold for the platform's own branch.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use Path::Tiny qw(path);

use_ok('Kubernetes::REST::AuthExec');

my $tmpdir = tempdir(CLEANUP => 1);
sub script {
    my ($name, $body) = @_;
    my $file = "$tmpdir/$name";
    path($file)->spew($body);
    return $file;
}

sub spawn {
    my ($script, @args) = @_;
    my $auth = bless {}, 'Kubernetes::REST::AuthExec';
    return $auth->_run_plugin_spawn($^X, $script, @args);
}

my $echo = script('echo', 'print join("|", @ARGV), "\n"; print STDERR "to-stderr\n"; print $ENV{SPAWN_PROBE} // "unset";');

subtest 'one argv element per argument, output returned, STDOUT restored' => sub {
    my $out = spawn($echo, 'a b', '$HOME;*', "q'uote");
    like $out, qr/\Aa b\|\$HOME;\*\|q'uote\r?\n/, 'arguments arrive unsplit and uninterpreted';
    ok defined fileno(STDOUT), 'STDOUT is open again';
};

subtest 'binary clean' => sub {
    my $bin = script('bin', 'binmode STDOUT; print "x\r\ny\0z";');
    is spawn($bin), "x\r\ny\0z", 'bytes unchanged';
};

subtest 'failures are worded like the fork branch' => sub {
    my $auth = bless {}, 'Kubernetes::REST::AuthExec';
    throws_ok { $auth->_run_plugin_spawn("$tmpdir/does not exist") }
        qr/could not be started: /, 'unstartable command';
    my $exit255 = script('exit255', 'exit 255');
    throws_ok { spawn($exit255) } qr/exited with status 255\b/,
        'a plugin exiting 255 is not mistaken for a failed start';
    my $fail = script('fail', 'exit 3');
    throws_ok { spawn($fail) } qr/exited with status 3\b/, 'exit status';
    SKIP: {
        skip 'no signals on Windows', 1 if $^O eq 'MSWin32';
        my $kill = script('kill', 'kill "TERM", $$; sleep 5');
        throws_ok { spawn($kill) } qr/killed by signal 15\b/, 'signal';
    }
};

subtest 'quoting for the Windows command line' => sub {
    my $auth = bless {}, 'Kubernetes::REST::AuthExec';
    # The C runtime's argv rules, as a parser, to read each result back.
    my $parse = sub {
        my ($q) = @_;
        my ($out, $in, $i) = ('', 0, 0);
        my @c = split //, $q;
        while ($i < @c) {
            if ($c[$i] eq '\\') {
                my $n = 0; $n++, $i++ while $i < @c and $c[$i] eq '\\';
                if ($i < @c and $c[$i] eq '"') { $out .= '\\' x int($n / 2); if ($n % 2) { $out .= '"'; $i++ } }
                else { $out .= '\\' x $n }
            }
            elsif ($c[$i] eq '"') { $in = !$in; $i++ }
            else { $out .= $c[$i++] }
        }
        return $out;
    };
    my @cases = (
        ['plain', '"plain"'],
        ['', '""'],
        ['   ', '"   "'],
        ['two  spaces', '"two  spaces"'],
        ['double"quote', '"double\\"quote"'],
        ['$HOME * & ; semi', '"$HOME * & ; semi"'],
        ['ends\\', '"ends\\\\"'],
        ['ends with space\\ ', '"ends with space\\ "'],
        ['back\\"quote', '"back\\\\\\"quote"'],
        ['trailing\\\\', '"trailing\\\\\\\\"'],
        ['"', '"\\""'],
        ['\\', '"\\\\"'],
        ['both "and" \\', '"both \\"and\\" \\\\"'],
    );
    for my $case (@cases) {
        my ($arg, $want) = @$case;
        my $got = $auth->_quote_win32_arg($arg);
        is $got, $want, "quoted: [$arg]";
        is $parse->($got), $arg, "reads back: [$arg]";
    }
};

done_testing;
