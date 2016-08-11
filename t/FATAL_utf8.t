#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Test::Warn;

use utf8::all;

# Fatal warning
warning_like
    { eval q/open my $out, '>', \my $mem; binmode $out, ':raw'; print $out "\x{FACE}"/; warn $@ }
    qr/Wide character/,
    'Fatal "Wide character" warning' or diag $@;

# Non-fatal warning
warning_like
    {
        open my $out, '>', \my $mem;
        binmode $out, ':raw';
        use warnings NONFATAL => 'utf8'; # downgrade to non-fatal utf8 warnings
        print $out "\x{FACE}"
    }
    'utf8',
    'Non-fatal "Wide character" warning' or diag $@;

warning_is
    {
        open my $out, '>', \my $mem;
        binmode $out, ':raw';
        no warnings FATAL => 'utf8'; # disable fatal utf8 warnings
        print $out "\x{FACE}";
    }
    [],
    'No "Wide character" warning';
