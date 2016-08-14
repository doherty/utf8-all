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

symlink "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "testlink.tmp"
    or die "Couldn't create symlink from testlink.tmp: $!";

END {
    unlink("testlink.tmp") or die "Unable to remove testlink.tmp: $!" if -l "testlink.tmp";
}

my $_UTF8 = find_encoding('UTF-8');

plan tests => 3;

my $linkdest = readlink('testlink.tmp');
my $utf8_linkdest;
{
    use utf8::all;
    $utf8_linkdest = readlink('testlink.tmp');
}

is $utf8_linkdest => "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", 'utf8 linkdest should be as expected';
is $linkdest => $_UTF8->encode($utf8_linkdest, FB_CROAK | LEAVE_SRC), 'encoded utf8 linkdest matches non-utf8';
is $_UTF8->decode($linkdest, FB_CROAK | LEAVE_SRC) => $utf8_linkdest, 'utf8 linkdest matches decoded non-utf8';
