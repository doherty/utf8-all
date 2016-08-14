#!perl

# Test that utf8::all is choosing the right encoding to not tickle
# thread bugs.

use strict;
use warnings;

# This is loaded before threads. It will not be aware of tests run in
# a thread.
use Test::More 0.96;
use Config;

BEGIN {
    plan skip_all => "Requires threads"
        if !$Config{usethreads};

    plan skip_all => "Thread support on Perl <= v5.10.0 is unstable"
        if $^V <= v5.10.0;

    plan tests => 1;
}

# Deliberately before loading threads so we don't cheat and check
# if threads are loaded, that would be brittle.
use utf8::all;

use threads;
use threads::shared;

my $ok :shared = 0;
my $t = threads->create(sub { $ok = 1; });
$t->join();
ok $ok, "threads ok with utf8::all";
