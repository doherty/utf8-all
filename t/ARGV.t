#!perl
# Test that utf8::all makes @ARGV utf8

BEGIN {
    @ARGV = qw(føø bar bāz);
}

use utf8::all;
use Test::More tests => 1;

is_deeply \@ARGV, [qw(føø bar bāz)];
