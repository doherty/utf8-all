#!perl
use strict;
use warnings;
use Test::More 0.96;
use Encode qw/find_encoding FB_CROAK LEAVE_SRC/;

plan skip_all => "Skipped: $^O does not have proper utf-8 file system support"
    if $^O =~ /MSWin32|cygwin|dos|os2/;

mkdir "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"
    or die "Couldn't create directory corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}: $!"
    unless -d "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}";

symlink "\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "corpus/testlink"
    or die "Couldn't create symlink to testlink: $!";

END {
    unlink("corpus/testlink") or die "Unable to remove corpus/testlink: $!" if -l "corpus/testlink";
}

my $_UTF8 = find_encoding('UTF-8');

plan tests => 3;

my $linkdest = readlink("corpus/testlink");
my $utf8_linkdest;
{
    use utf8::all;
    $utf8_linkdest = readlink("corpus/testlink");
}

is $utf8_linkdest => "\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", 'utf8 linkdest should be as expected';
is $linkdest => $_UTF8->encode($utf8_linkdest, FB_CROAK | LEAVE_SRC), 'encoded utf8 linkdest matches non-utf8';
is $_UTF8->decode($linkdest, FB_CROAK | LEAVE_SRC) => $utf8_linkdest, 'utf8 linkdest matches decoded non-utf8';
