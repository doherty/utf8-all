#!perl
# utf8::all should have lexical effect

use Test::More tests => 2;

BEGIN {
    @ARGV = qw(føø bar bāz);
}

# use utf8::all in a narrow lexical scope.
# It shouldn't effect the rest of the program.
{ use utf8::all }

is_deeply \@ARGV, ["f\x{f8}\x{f8}", 'bar', "b\x{101}z"] or diag explain \@ARGV;

{ # Bring utf8::all back into effect
    use utf8::all;
    is_deeply \@ARGV, [qw(føø bar bāz)];
}
