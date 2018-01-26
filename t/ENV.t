#!perl
# Test that utf8::all makes @ENV utf8
use strict;
use warnings;

use Encode;

use Test::More tests => 12;

# føø
local $ENV{FOO} = join '', map {chr $_} ( 0x66, 0xc3, 0xb8, 0xc3, 0xb8 );

# bar
local $ENV{BAR} = 'bar';

# bāz
local $ENV{BAZ} = join '', map {chr $_} ( 0x62, 0xc4, 0x81, 0x7a );

# テスト
local $ENV{BOO} = join '', map {chr $_} (0xe3, 0x83, 0x86, 0xe3, 0x82, 0xb9, 0xe3, 0x83, 0x88);

use utf8::all;

# føø bar bāz テスト but now as unicode characters
is $ENV{FOO}, "\x{66}\x{f8}\x{f8}", "ENV as unicode characters instead of utf-8 octets";
is(length($ENV{FOO}), 3, "string is seen as 3 char bytes when seen as utf-8");
ok(Encode::is_utf8($ENV{FOO}), "String is seen as Perl Internal UTF-8");

is $ENV{BAR}, "\x{62}\x{61}\x{72}", "ENV as unicode characters instead of utf-8 octets";
is(length($ENV{BAR}), 3, "string is seen as 3 char bytes when seen as utf-8");
ok(Encode::is_utf8($ENV{BAR}), "String is seen as Perl Internal UTF-8");

is $ENV{BAZ}, "\x{62}\x{101}\x{7a}", "ENV as unicode characters instead of utf-8 octets";
is(length($ENV{BAZ}), 3, "string is seen as 5 char bytes when seen as utf-8");
ok(Encode::is_utf8($ENV{BAZ}), "String is seen as Perl Internal UTF-8");

is $ENV{BOO}, "\x{30c6}\x{30b9}\x{30c8}", "ENV as unicode characters instead of utf-8 octets";
is(length($ENV{BOO}), 3, "string is seen as 9 char bytes when seen as utf-8");
ok(Encode::is_utf8($ENV{BOO}), "String is seen as Perl Internal UTF-8");

