#!perl
# Test that ust8::all with GLOBAL does change @ARGV, STDIN, STDOUT, STDERR
use strict;
use warnings;

BEGIN {
    # String literals are still utf-8 encoded octets here!
    @ARGV = qw(føø bar bāz テスト);
}

package not_main;

use utf8::all 'GLOBAL';
use PerlIO;
use Test::More;

SKIP: {
        # If we run with the Perl Unicode flag to automatically
        # convert the command-line arguments to unicode characters,
        # we need to skip this test
    skip 'Perl Unicode flag set to automatically convert command-line arguments', 1 if (${^UNICODE} & 32);
    # føø bar bāz テスト but now as unicode characters
    is_deeply \@ARGV => [
        "\x{66}\x{f8}\x{f8}",
        "\x{62}\x{61}\x{72}",
        "\x{62}\x{101}\x{7a}",
        "\x{30c6}\x{30b9}\x{30c8}"
    ], '@ARGV as unicode characters instead of utf-8 octets';
}

# Test the standard handles are utf-8
my $utf8_flag = 1;
for my $fh (*STDIN, *STDOUT, *STDERR) {
    my @layers = PerlIO::get_layers($fh);
    ok(grep(m/utf8/, @layers), 'utf8 appears in the perlio layers')
        or diag explain { $fh => \@layers };
    ok(grep(m/utf-?8[-_]strict/, @layers), 'utf-?8[-_]strict appears in the perlio layers')
        or diag explain { $fh => \@layers };
}

done_testing;
