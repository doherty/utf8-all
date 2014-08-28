#!perl
use strict;
use warnings;
use Test::More 0.96;
use Encode qw/decode FB_CROAK/;
use File::Find;
use Cwd;

plan skip_all => q/Can't Unicodify find or cwd on Windows/
    if $^O eq 'Win32';

mkdir "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"
    or die "Couldn't create directory corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}: $!"
    unless -d "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}";
open my $touch, '>', "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}/bar"
    or die "Couldn't open corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}/bar for writing: $!";
close $touch
    or die "Couldn't close corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}/bar: $!";

plan tests => 4;

subtest utf8find => sub {
    plan tests => 5;

    my @files;
    File::Find::find( { no_chdir => 0, wanted => sub { push(@files, $_) if $_ !~ /\.{1,2}/ } }, 'corpus');
    @files = sort @files;

    my @utf8_files;
    {
        use utf8::all qw(:all);
        File::Find::find( { no_chdir => 0, wanted => sub { push(@utf8_files, $_) if $_ !~ /\.{1,2}/ } }, 'corpus');
        @utf8_files = sort @utf8_files;
    }

    is_deeply \@utf8_files, [sort "\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "bar", "testfile"];
    is   $files[0] => $utf8_files[0];
    is   $files[1] => $utf8_files[1];
    isnt $files[2] => $utf8_files[2];
    is   decode('UTF-8', $files[2], FB_CROAK) => $utf8_files[2];
};

subtest utf8finddepth => sub {
    plan tests => 5;

    my @files;
    File::Find::finddepth( { no_chdir => 0, wanted => sub { push(@files, $_) if $_ !~ /\.{1,2}/ } }, 'corpus');
    @files = sort @files;

    my @utf8_files;
    {
        use utf8::all qw(:all);
        File::Find::finddepth( { no_chdir => 0, wanted => sub { push(@utf8_files, $_)  if $_ !~ /\.{1,2}/ } }, 'corpus');
        @utf8_files = sort @utf8_files;
    }

    is_deeply \@utf8_files, [sort "\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "bar", "testfile"];
    is   $files[0] => $utf8_files[0];
    is   $files[1] => $utf8_files[1];
    isnt $files[2] => $utf8_files[2];
    is   decode('UTF-8', $files[2], FB_CROAK) => $utf8_files[2];
};

subtest utf8cwd => sub {
    plan tests => 6;

    chdir("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}") or die "Couldn't chdir to corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}";
    my @cwdirs = (Cwd::getcwd(), Cwd::cwd(), Cwd::fastcwd());

    my @utf8_cwdirs;
    {
        use utf8::all qw(:all);
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

    my @abs = (Cwd::abs_path("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), Cwd::realpath("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), Cwd::fast_abs_path("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"));

    my @utf8_abs;
    {
        use utf8::all qw(:all);
        @utf8_abs = (Cwd::abs_path("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), Cwd::realpath("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), Cwd::fast_abs_path("corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"));
    }
    for (my $i=0 ; $i<3; $i++) {
        like $utf8_abs[$i] => qr/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}$/;
        isnt $abs[$i] => $utf8_abs[$i];
        is   decode('UTF-8', $abs[$i], FB_CROAK) => $utf8_abs[$i];
    }
};

