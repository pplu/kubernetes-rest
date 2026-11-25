#!/usr/bin/env perl
# A program that installs *CORE::GLOBAL::exec or *CORE::GLOBAL::system before
# loading us (test guards, Test::Mock modules) turns the indirect block form
# `exec {$cmd} ...` / `system { $cmd[0] } @cmd` into a syntax error at load
# time. The block forms are spelled CORE::exec / CORE::system, and nothing
# under lib/ or bin/ may bring the bare form back.
use strict;
use warnings;
use Test::More;

BEGIN {
  no warnings 'once';
  *CORE::GLOBAL::exec   = sub { die "guard: exec called\n" };
  *CORE::GLOBAL::system = sub { die "guard: system called\n" };
}

use FindBin;
use File::Find;
use lib "$FindBin::Bin/../lib";

for my $module (qw(
  Kubernetes::REST::AuthExec
  Kubernetes::REST::Kubeconfig
  Kubernetes::REST::CLI::Minikube
)) {
  my $ok = eval "require $module; 1";
  ok($ok, "$module loads with CORE::GLOBAL::exec and ::system overridden")
    or diag $@;
}

my $root = "$FindBin::Bin/..";
my @files;
find({ no_chdir => 1, wanted => sub {
  push @files, $_ if -f $_ && /\.pm\z/;
} }, "$root/lib");
push @files, glob "$root/bin/*";
@files = grep { -f } @files;
ok(scalar @files, 'found files under lib/ and bin/');

for my $file (sort @files) {
  open my $fh, '<', $file or die "Cannot open $file: $!";
  my ($in_pod, @bad);
  while (my $line = <$fh>) {
    if ($line =~ /^=(\w+)/) { $in_pod = $1 ne 'cut'; next }
    next if $in_pod;
    last if $line =~ /^__(?:END|DATA)__\b/;
    (my $code = $line) =~ s/#.*//;
    # a bare exec/system block form; not a method or sub named exec
    while ($code =~ /(?<![\w:>\$\@%&])(?<!sub )(?<!sub  )(exec|system)\s*\{/g) {
      push @bad, "line $.: $1 { ...";
    }
  }
  close $fh;
  (my $rel = $file) =~ s{^\Q$root\E/}{};
  is_deeply(\@bad, [], "$rel has no exec {...}/system {...} without CORE::")
    or diag join "\n", @bad;
}

done_testing;
