#!perl
# Test that ust8::all from non-main package does not change @ARGV, STDIN, STDOUT, STDERR
use strict;
use warnings;

BEGIN {
    # String literals are still utf-8 encoded octets here!
    @ARGV = qw(føø bar bāz テスト);
}

package not_main;

use utf8::all;
use PerlIO;
use Test::More;


SKIP: {
        # If we run with the Perl Unicode flag to automatically
        # convert the command-line arguments to unicode characters,
        # we need to skip this test
    skip 'Perl Unicode flag set to automatically convert command-line arguments', 1 if (${^UNICODE} & 32);
    # føø bar bāz テスト still as utf-8 encoded octets
    is_deeply \@ARGV => [
        "\x{66}\x{c3}\x{b8}\x{c3}\x{b8}",
        "\x{62}\x{61}\x{72}",
        "\x{62}\x{c4}\x{81}\x{7a}",
        "\x{e3}\x{83}\x{86}\x{e3}\x{82}\x{b9}\x{e3}\x{83}\x{88}"
    ], '@ARGV as utf-8 octets';
}

# Test the standard handles are NOT utf-8
my $utf8_flag = 1;
for my $fh (*STDIN, *STDOUT, *STDERR) {
    my @layers = PerlIO::get_layers($fh);
  SKIP: {
        # If we have the Perl Unicode flag set that adds the UTF-8 layer,
        # we need to skip this test.
        skip 'Perl Unicode flag set that always adds UTF-8 layer', 1 if (${^UNICODE} & $utf8_flag);
        ok(!grep(/utf8/, @layers), q{utf8 does not appear in perlio layers})
        or diag explain { $fh => \@layers };
    }
    ok(!grep(m/utf-?8[-_]strict/, @layers), q{utf-?8[-_]strict does not appear in the perlio layers})
        or diag explain { $fh => \@layers };
    $utf8_flag *= 2;
}

ok((open my $test_fh, ">", "perlio_test"), 'open file for writing with utf8::all');
END { unlink "perlio_test" }
my @layers = PerlIO::get_layers($test_fh);
ok(grep(m/utf8/, @layers), 'utf8 appears in the perlio layers')
    or diag explain { $test_fh => \@layers };
ok(grep(m/utf-?8[-_]strict/, @layers), 'utf-?8[-_]strict appears in the perlio layers')
    or diag explain { $test_fh => \@layers };

done_testing;
