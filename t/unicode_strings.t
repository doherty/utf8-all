#!perl
# utf8::all should turn on feature qw(unicode_strings)

use strict;
use warnings;
use Config;
use Test::More;
plan $^V >= v5.14.0
    ? (tests => 13)
    : (skip_all => q/character set modifiers aren't available until 5.14.0/);

use constant HAVE_LOCALE => $Config{i_locale};

my $code = <<'TEST_CODE';
# Straight out of t/re/pat.t
{   # Test that charset modifier work, and are interpolated
    is(qr/\b\v$/, '(?^:\b\v$)', 'Verify no locale, no unicode_strings gives default modifier');
    is(qr/(?l:\b\v$)/, '(?^:(?l:\b\v$))', 'Verify infix l modifier compiles');
    is(qr/(?u:\b\v$)/, '(?^:(?u:\b\v$))', 'Verify infix u modifier compiles');
    is(qr/(?l)\b\v$/, '(?^:(?l)\b\v$)', 'Verify (?l) compiles');
    is(qr/(?u)\b\v$/, '(?^:(?u)\b\v$)', 'Verify (?u) compiles');

    my $dual = qr/\b\v$/;
    use locale;
    my $locale = qr/\b\v$/;
    SKIP: {
        skip "No locale on this system, /l flag not present", 1 if !HAVE_LOCALE;
        is($locale,    '(?^l:\b\v$)', 'Verify has l modifier when compiled under use locale');
    }
    no locale;

    use utf8::all; # use utf8::all instead of feature qw(unicode_strings);
    my $unicode = qr/\b\v$/;
    is($unicode,    '(?^u:\b\v$)', 'Verify has u modifier when compiled under unicode_strings');
    is(qr/abc$dual/,    '(?^u:abc(?^:\b\v$))', 'Verify retains d meaning when interpolated under locale');
    SKIP: {
        skip "No locale on this system, /l flag not present", 1 if !HAVE_LOCALE;
        is(qr/abc$locale/,    '(?^u:abc(?^l:\b\v$))', 'Verify retains l when interpolated under unicode_strings');
    }

    no feature 'unicode_strings';
    SKIP: {
        skip "No locale on this system, /l flag not present", 1 if !HAVE_LOCALE;
        is(qr/abc$locale/,    '(?^:abc(?^l:\b\v$))', 'Verify retains l when interpolated outside locale and unicode strings');
    }
    is(qr/def$unicode/,    '(?^:def(?^u:\b\v$))', 'Verify retains u when interpolated outside locale and unicode strings');

    use locale;
        SKIP: {
        skip "No locale on this system, /l flag not present", 2 if !HAVE_LOCALE;

        is(qr/abc$dual/,    '(?^l:abc(?^:\b\v$))', 'Verify retains d meaning when interpolated under locale');
        is(qr/abc$unicode/,    '(?^l:abc(?^u:\b\v$))', 'Verify retains u when interpolated under locale');
    }
}
TEST_CODE
eval $code;