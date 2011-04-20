#!perl
# Test opening an actual file
use utf8::all;
use PerlIO;
use Test::More tests => 4;

ok open my $in, '<', 'corpus/testfile';
my @layers = PerlIO::get_layers($in);
ok(grep(m/utf8/, @layers), 'utf8 appears in the perlio layers')
    or diag explain { $fh => \@layers };
ok(grep(m/utf-8-strict/, @layers), 'utf-8-strict appears in the perlio layers')
    or diag explain { $fh => \@layers };

my $contents = do { local $/; <$in>};
is $contents, "f\x{f8}\x{f8}\n", 'unicode retrieved OK';
