use strict;
use warnings;
use Test::More tests => 3;
use Test::Warn;
use warnings FATAL=>'utf8';

# Fatal warning
warning_like
    { eval q/open my $out, '>:raw', \my $mem; print $out "\x{FACE}"/; warn $@ }
    qr/Wide character/, # warning categories only work for non-fatal warnings
    'Fatal "Wide character" warning' or diag $@;

# Non-fatal warning
warning_like
    {
        open my $out, '>:raw', \my $mem;
        use warnings NONFATAL => 'utf8';    # downgrade to non-fatal utf8 warnings
        print $out "\x{FACE}"
    }
    'utf8',#qr/Wide character/,
    'Non-fatal "Wide character" warning' or diag $@;

warning_is
    {
        open my $out, '>:raw', \my $mem;
        no warnings FATAL => 'utf8';    # disable fatal utf8 warnings
        print $out "\x{FACE}";
    }
    [],
    'No "Wide character" warning';