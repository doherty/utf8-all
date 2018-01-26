#!perl
# Test that utf8::all makes @ENV utf8
use strict;
use warnings;

use Encode;

use Test::More tests =>12;

# føø
local $ENV{FOO} = join '', map {chr $_} ( 0x66, 0xc3, 0xb8, 0xc3, 0xb8 );

# bar
local $ENV{BAR} = 'bar';

# bāz
local $ENV{BAZ} = join '', map {chr $_} ( 0x62, 0xc4, 0x81, 0x7a );

# テスト
local $ENV{BOO} = join '', map {chr $_} (0xe3, 0x83, 0x86, 0xe3, 0x82, 0xb9, 0xe3, 0x83, 0x88);
use utf8::all qw/NO-GLOBAL/;

{	
	
	is($ENV{FOO}, "\x{66}\x{c3}\x{b8}\x{c3}\x{b8}", "ENV{FOO} $ENV{FOO} is not unicode characters instead of utf-8 octets");
	is(length($ENV{FOO}), 5, "string is seen as 5 char bytes when not seen as utf-8");
	ok(!Encode::is_utf8($ENV{FOO}), "String is not seen as Perl Internal UTF-8");

	is($ENV{BAR}, "\x{62}\x{61}\x{72}", "ENV{BAR} $ENV{BAR} is not unicode characters instead of utf-8 octets");
	is(length($ENV{BAR}), 3, "string is seen as 3 char bytes when not seen as utf-8");
	ok(!Encode::is_utf8($ENV{BAR}), "String is not seen as Perl Internal UTF-8");

	is($ENV{BAZ}, "\x{62}\x{c4}\x{81}\x{7a}", "ENV{BAZ} $ENV{BAZ} is not unicode characters instead of utf-9 octets");
	is(length($ENV{BAZ}), 4, "string is seen as 5 char bytes when not seen as utf-8");
	ok(!Encode::is_utf8($ENV{BAZ}), "String is not seen as Perl Internal UTF-8");

	is($ENV{BOO}, "\x{e3}\x{83}\x{86}\x{e3}\x{82}\x{b9}\x{e3}\x{83}\x{88}", "ENV{BOO} $ENV{BOO} is not unicode characters instead of utf-8 octets");
	is(length($ENV{BOO}), 9, "string is seen as 9 char bytes when not seen as utf-8");
	ok(!Encode::is_utf8($ENV{BOO}), "String is not seen as Perl Internal UTF-8");

}

