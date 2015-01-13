#!perl
# Test that utf8::all makes @ARGV utf8

BEGIN {
    # String literals are still utf-8 encoded octets here!
    @ARGV = qw(føø bar bāz テスト);
}

use utf8::all;
use Test::More tests => 1;

# føø bar bāz テスト but now as unicode characters
is_deeply \@ARGV => [
    "\x{66}\x{f8}\x{f8}",
    "\x{62}\x{61}\x{72}",
    "\x{62}\x{101}\x{7a}",
    "\x{30c6}\x{30b9}\x{30c8}"
], '@ARGV as unicode characters instead of utf-8 octets';
