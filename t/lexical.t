#!perl
# utf8::all should have lexical effect (except for @ARGV!)

use Test::More tests => 4;

my $expected_unicode = "\x{30c6}\x{30b9}\x{30c8}"; # Unicode characters
my $expected_utf8    = "\x{e3}\x{83}\x{86}\x{e3}\x{82}\x{b9}\x{e3}\x{83}\x{88}"; # UTF-8 encoded octets

is "テスト" => $expected_utf8, 'Literal string should be utf-8 encoded octets without utf8::all';

{
    use utf8::all;
    is "テスト" => $expected_unicode, 'Literal string should be characters under utf8::all';
}

is "テスト" => $expected_utf8, 'Literal string should be utf-8 encoded octets without utf8::all (again)';

use utf8::all;
is "テスト" => $expected_unicode, 'Literal string should be characters under utf8::all (again)';
