#!perl
use strict;
use warnings;
use Test::More 0.96;
use Encode qw/find_encoding FB_CROAK LEAVE_SRC/;

plan skip_all => "$^O does not have proper utf-8 file system support"
    if $^O =~ /MSWin32|cygwin|dos|os2/;

mkdir "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"
    or die "Couldn't create directory corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}: $!"
    unless -d "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}";

my $_UTF8 = find_encoding('UTF-8');

plan tests => 3*3;

my $cmd = 'ls -1 corpus';

my $expected = "testfile\n\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}\n";

my $result;
my $utf8_result;

sub sort_res {
    return join("\n", sort(split("\n", shift)));
}

sub test_res {
    my $test = shift;
    my $result = shift;
    my $utf8_result = shift;

    is sort_res($utf8_result) => sort_res($expected), "$test utf8 result should be as expected";
  SKIP: {
        # If we have the Perl Unicode flag set that adds the UTF-8 layer,
        # we need to skip these tests.
        skip 'Perl Unicode flag set that always adds UTF-8 layer to input', 2 if (${^UNICODE} & 8);

        is $result => $_UTF8->encode($utf8_result, FB_CROAK | LEAVE_SRC), "$test encoded utf8 result matches non-utf8";
        is $_UTF8->decode($result, FB_CROAK | LEAVE_SRC) => $utf8_result, "$test utf8 result matches decoded non-utf8";
    }
}

# readpipe
$result = readpipe($cmd);
{
    use utf8::all;
    $utf8_result = readpipe($cmd);
}
test_res('readpipe', $result, $utf8_result);

# Backtick
$result = `$cmd`;
{
    use utf8::all;
    $utf8_result = `$cmd`;
}
test_res('Backtick', $result, $utf8_result);

# qx
$result = qx{$cmd};
{
    use utf8::all;
    $utf8_result = qx{$cmd};
}
test_res('qx', $result, $utf8_result);
