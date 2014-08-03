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

subtest utf8cwd => sub {
    plan tests => 6;

    chdir("corpus/みかちゃん") or die "Can't chdir to 'corpus/みかちゃん'";
    my @cwdirs = (Cwd::getcwd(), Cwd::cwd(), Cwd::fastcwd());

    my @utf8_cwdirs;
    {
        use utf8::all;
        @utf8_cwdirs = (Cwd::getcwd(), Cwd::cwd(), Cwd::fastcwd());
    }
    for (my $i=0 ; $i<3; $i++) {
        isnt $cwdirs[$i] => $utf8_cwdirs[$i];
        is   decode('UTF-8', $cwdirs[$i], FB_CROAK) => $utf8_cwdirs[$i];
    }

    chdir("../..") or die "Can't chdir back to original dir";
};

subtest utf8abs_path => sub {
    plan tests => 9;

    my @abs = (Cwd::abs_path("corpus/みかちゃん"), Cwd::realpath("corpus/みかちゃん"), Cwd::fast_abs_path("corpus/みかちゃん"));

    my @utf8_abs;
    {
        use utf8::all;
        @utf8_abs = (Cwd::abs_path("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), Cwd::realpath("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), Cwd::fast_abs_path("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"));
    }
    for (my $i=0 ; $i<3; $i++) {
        like $utf8_abs[$i] => qr/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}$/;
        isnt $abs[$i] => $utf8_abs[$i];
        is   decode('UTF-8', $abs[$i], FB_CROAK) => $utf8_abs[$i];
    }
};

