#!perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;

plan skip_all => "$^O does not have proper utf-8 file system support"
    if $^O =~ /MSWin32|cygwin|dos|os2/;

plan tests => 6;

# Tests if setting $utf8::all::UTF8_CHECK has the required result

use Encode ();
use utf8::all;

no warnings FATAL => 'utf8'; # disable fatal utf8 warnings

# String with an illegal Unicode character
my $faulty_string = "Illegal \x{d800} character";

# Warn on faulty utf-8
{
    local $utf8::all::UTF8_CHECK = Encode::FB_WARN;
    Test::Warn::warning_like
          {
              glob($faulty_string);
          }
          qr/"\\x\{d800\}" does not map to (utf8|UTF-8)/,
          'warn on encoding error: glob';
    Test::Warn::warning_like
          {
              readlink($faulty_string);
          }
          qr/"\\x\{d800\}" does not map to (utf8|UTF-8)/,
          'warn on encoding error: readlink';
}

# Croak on faulty utf-8
{
    Test::Exception::throws_ok
          {
              glob($faulty_string);
          }
          qr/"\\x\{d800\}" does not map to (utf8|UTF-8)/,
          'croak on encoding error (default): glob';
    Test::Exception::throws_ok
          {
              readlink($faulty_string);
          }
          qr/"\\x\{d800\}" does not map to (utf8|UTF-8)/,
          'croak on encoding error (default): readlink';
}

# Nothing on faulty utf-8
{
    local $utf8::all::UTF8_CHECK = Encode::FB_DEFAULT;
    Test::Warn::warning_is
          {
              glob($faulty_string);
          }
          [],
          'no warn on encoding error: glob';
    Test::Warn::warning_is
          {
              readlink($faulty_string);
          }
          [],
          'no warn on encoding error: readlink';
}
