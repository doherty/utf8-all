#!perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;

plan tests => 9;

# Tests if setting $utf8::all::UTF8_CHECK has the required result

use Encode ();
use utf8::all;

# Argument to abs_path with an illegal Unicode character
my $faulty_string = "Illegal \x{d800} character";

# Croak on faulty utf-8
{
    Test::Exception::throws_ok
          {
              glob($faulty_string);
          }
          qr/"\\x\{d800\}" does not map to utf8/,
          'croak on encoding error (default)';
    Test::Exception::throws_ok
          {
              readlink($faulty_string);
          }
          qr/"\\x\{d800\}" does not map to utf8/,
          'croak on encoding error (default)';
    Test::Exception::throws_ok
          {
              readdir($faulty_string);
          }
          qr/"\\x\{d800\}" does not map to utf8/,
          'croak on encoding error (default)';
}

# Warn on faulty utf-8
{
    local $utf8::all::UTF8_CHECK = Encode::FB_WARN;
    Test::Warn::warning_is
          {
              glob($faulty_string);
          }
          qq("\\x\{d800\}" does not map to utf8),
          'warn on encoding error';
    Test::Warn::warning_is
          {
              readlink($faulty_string);
          }
          qq("\\x\{d800\}" does not map to utf8),
          'warn on encoding error';
    Test::Warn::warnings_like
          {
              readdir($faulty_string);
          }
          [qr/^"\\x\{d800\}" does not map to utf8/, qr/^readdir\(\) attempted on invalid dirhandle/ ],
          'warn on encoding error';
}

# Nothing on faulty utf-8
{
    local $utf8::all::UTF8_CHECK = Encode::FB_DEFAULT;
    Test::Warn::warning_is
          {
              glob($faulty_string);
          }
          [],
          'no warn on encoding error';
    Test::Warn::warning_is
          {
              readlink($faulty_string);
          }
          [],
          'no warn on encoding error';
    Test::Warn::warning_like
          {
              readdir($faulty_string);
          }
          qr/^readdir\(\) attempted on invalid dirhandle/,
          'no warn on encoding error';
}
