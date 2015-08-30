#!perl
# Test that utf8::all makes @ARGV utf8 (but not when not loaded from main)

BEGIN {
    # String literals are still utf-8 encoded octets here!
    @ARGV = qw(føø bar bāz テスト);
}

package not_main;

use utf8::all;
use Test::More tests => 1;

is_deeply \@ARGV => [
    # føø bar bāz テスト still as utf-8 encoded octets
    "\x{66}\x{c3}\x{b8}\x{c3}\x{b8}",
    "\x{62}\x{61}\x{72}",
    "\x{62}\x{c4}\x{81}\x{7a}",
    "\x{e3}\x{83}\x{86}\x{e3}\x{82}\x{b9}\x{e3}\x{83}\x{88}",
], 'non main package: @ARGV still as utf-8 encoded octets';
