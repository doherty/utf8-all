#!perl
# Test that utf8::all makes @ARGV utf8 (but not when not loaded from main)

BEGIN {
    @ARGV = qw(føø bar bāz);
}

package not_main;

use utf8::all;
use Test::More tests => 1;
use Encode;

is_deeply \@ARGV, [map { Encode::encode('UTF-8', $_) } (qw(føø bar bāz))];
