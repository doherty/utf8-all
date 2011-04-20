#!perl
# Test that utf8::all doesn't double encode @ARGV [perl5i github 176]

BEGIN {
    @ARGV = qw(føø bar bāz);
}

{
    package Foo;
    use utf8::all;
}

use utf8::all;
use Test::More tests => 1;

is_deeply \@ARGV, [qw(føø bar bāz)];
