#!perl
# no utf8::all should disable its effects lexically
# Note: Changes to @ARGV, STDIN, STDOU, and STDERR are always global!

use Test::More tests => 17;
use PerlIO;

my $expected_unicode = "\x{30c6}\x{30b9}\x{30c8}"; # Unicode characters
my $expected_utf8    = "\x{e3}\x{83}\x{86}\x{e3}\x{82}\x{b9}\x{e3}\x{83}\x{88}"; # UTF-8 encoded octets

use utf8::all;

is "テスト" => $expected_unicode, 'Literal string should be characters under utf8::all';

{
    no utf8::all;
    is "テスト" => $expected_utf8, 'Literal string should be utf-8 encoded octets without utf8::all';

    # Test the standard handles and all newly opened handles are not utf8
    ok((open my $out, ">", "lexical_octets.tmp"), 'open file for writing without utf8::all');
    END { unlink "lexical_octets.tmp" }
    ok((open my $in, '<', 'corpus/testfile'), 'open file for reading without utf8::all');
    my $contents = do { local $/; <$in>};
    is $contents, "$expected_utf8\n", 'octets retreived OK';
    my %handles = (
        IN     => $in,
        OUT    => $out,
    );
    for my $fh (keys %handles) {
        my @layers = PerlIO::get_layers($handles{$fh});
        ok(!grep(m/utf8/, @layers), "$fh: utf8 does not appear in the perlio layers")
            or diag explain { $fh => \@layers };
        ok(!grep(m/utf-?8[-_]strict/, @layers), "$fh: utf-?8[-_]strict does not appear in the perlio layers")
            or diag explain { $fh => \@layers };
    }

}

is "テスト" => $expected_unicode, 'Literal string should be characters under utf8::all (again)';

# Test the standard handles and all newly opened handles are utf8 (again)
ok((open my $out, ">", "lexical_unicode.tmp"), 'open file for writing with utf8::all');
END { unlink "lexical_unicode.tmp" }
ok((open my $in, '<', 'corpus/testfile'), 'open file for reading with utf8::all');
my $contents = do { local $/; <$in>};
is $contents, "$expected_unicode\n", 'unicode retrieved OK';
my %handles = (
    IN     => $in,
    OUT    => $out,
);
for my $fh (keys %handles) {
    my @layers = PerlIO::get_layers($handles{$fh});
    ok(grep(m/utf8/, @layers), "$fh: utf8 does appear in the perlio layers")
        or diag explain { $fh => \@layers };
    ok(grep(m/utf-?8[-_]strict/, @layers), "$fh: utf-?8[-_]strict does appear in the perlio layers")
        or diag explain { $fh => \@layers };
}
