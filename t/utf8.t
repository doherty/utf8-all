#!perl
# utf8::all turns on utf8
use strict;
use warnings;

use PerlIO;
use Test::More;

# Test with it on
{
    use utf8::all;

    is length "utf8::all is MËTÁŁ" => 18, 'unicode string is characters';

    # Test the standard handles and all newly opened handles are utf8
    ok((open my $test_fh, ">", "perlio_test"), 'open file for writing with utf8::all');
    END { unlink "perlio_test" }
    for my $fh (*STDOUT, *STDIN, *STDERR, $test_fh) {
        my @layers = PerlIO::get_layers($fh);
        ok(grep(m/utf8/, @layers), 'utf8 appears in the perlio layers')
            or diag explain { $fh => \@layers };
        ok(grep(m/utf-?8[-_]strict/, @layers), 'utf-?8[-_]strict appears in the perlio layers')
            or diag explain { $fh => \@layers };
    }
}


# And off
{
    is length "utf8::all is MËTÁŁ" => 21, 'unicode string is octets';

    ok((open my $test_fh, ">", "perlio_test2"), 'open file for writing with utf8::all');
    END { unlink "perlio_test2" }

    my @layers = PerlIO::get_layers($test_fh);
  SKIP: {
        # If we have the Perl Unicode flag set that adds the UTF-8 layer,
        # we need to skip this test.
        skip 'Perl Unicode flag set that always adds UTF-8 layer to output', 1 if (${^UNICODE} & 16);
        ok(!grep(/utf8/, @layers), q{utf8 does not appear in perlio layers})
            or diag explain { $test_fh => \@layers };
    }
    ok(!grep(m/utf-?8[-_]strict/, @layers), q{utf-?8[-_]strict does not appear in the perlio layers})
        or diag explain { $test_fh => \@layers };

}

done_testing;
