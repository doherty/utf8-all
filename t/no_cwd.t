#!perl

use strict;
use warnings;
use Test::More 0.96;
use Encode qw/decode FB_CROAK/;
use Cwd;

plan skip_all => q/Can't Unicodify cwd on Windows/
    if $^O eq 'Win32';

mkdir "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"
    or die "Couldn't create directory corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}: $!"
    unless -d "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}";

plan tests => 2;

subtest 'No UTF8 Cwd::cwd' => sub {
    plan tests => 3;

    chdir("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}") or die "Couldn't chdir to corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}";
    my @cwdirs = (Cwd::getcwd(), Cwd::cwd(), Cwd::fastcwd());

    my @utf8_cwdirs;
    {
        use utf8::all;
        @utf8_cwdirs = (Cwd::getcwd(), Cwd::cwd(), Cwd::fastcwd());
    }
    for (my $i=0 ; $i<3; $i++) {
        is $cwdirs[$i] => $utf8_cwdirs[$i];
    }

    chdir("../..") or die "Can't chdir back to original dir";
};

subtest 'No UTF8 Cwd::abs_path' => sub {
    plan tests => 3;

    my @abs = (Cwd::abs_path("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), Cwd::realpath("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), Cwd::fast_abs_path("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"));

    my @utf8_abs;
    {
        use utf8::all;
        @utf8_abs = (Cwd::abs_path("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), Cwd::realpath("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), Cwd::fast_abs_path("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"));
    }
    for (my $i=0 ; $i<3; $i++) {
        is $abs[$i] => $utf8_abs[$i];
    }
};

