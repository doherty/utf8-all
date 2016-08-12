#!perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;

plan skip_all => "Skipped: $^O does not have proper utf-8 file system support"
    if $^O =~ /MSWin32|cygwin|dos|os2/;

plan tests => 9;

# Tests if setting $utf8::all::UTF8_CHECK has the required result

use Encode ();
use utf8::all;

no warnings FATAL => 'utf8'; # disable fatal utf8 warnings

# String with an illegal Unicode character
my $faulty_string = "Illegal \x{d800} character";

# Warn on faulty utf-8
{
    local $utf8::all::UTF8_CHECK = Encode::FB_WARN;
    Test::Warn::warning_is
          {
              glob($faulty_string);
          }
          qq("\\x\{d800\}" does not map to utf8),
          'warn on encoding error: glob';
    Test::Warn::warning_is
          {
              readlink($faulty_string);
          }
          qq("\\x\{d800\}" does not map to utf8),
          'warn on encoding error: readlink';
    Test::Warn::warnings_like
          {
              readdir($faulty_string);
          }
          # readdir throws additional warning on invalid character
          [ qr/^"\\x\{d800\}" does not map to utf8/, qr/dirhandle/ ],
          'warn on encoding error: readdir';
}

# Croak on faulty utf-8
{
    Test::Exception::throws_ok
          {
              glob($faulty_string);
          }
          qr/"\\x\{d800\}" does not map to utf8/,
          'croak on encoding error (default): glob';
    Test::Exception::throws_ok
          {
              readlink($faulty_string);
          }
          qr/"\\x\{d800\}" does not map to utf8/,
          'croak on encoding error (default): readlink';
    Test::Exception::throws_ok
          {
              readdir($faulty_string);
          }
          qr/"\\x\{d800\}" does not map to utf8/,
          'croak on encoding error (default): readdir';
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
    Test::Warn::warning_like
          {
              readdir($faulty_string);
          }
          # readdir throws warning on invalid character
          qr/dirhandle/,
          'no warn on encoding error: readdir';
}
