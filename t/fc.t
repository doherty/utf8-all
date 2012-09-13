#!perl
# utf8::all should turn on feature qw(unicode_strings)

use strict;
use warnings;
use Test::More;
plan $^V >= v5.16.0
    ? (tests => 3)
    : (skip_all => q/Can't enable fc on perl < 5.16.0/);

{
    no warnings qw(syntax);
    eval q/fc 'ABC' eq fc 'abc';/;
    ok $@, 'Got an error using fc without utf8::all...';
    like $@ => qr/^syntax error/, '...and the error was a syntax error' or diag $@;
}

eval q/ use utf8::all; fc 'XYZ' eq fc 'xyz'; /;
ok !$@, 'no error with utf8::all' or diag $@;