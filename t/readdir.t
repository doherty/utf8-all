#!perl
use strict;
use warnings;
use Test::More 0.96;
use Encode qw/decode FB_CROAK/;

plan skip_all => "$^O does not have proper utf-8 file system support"
    if $^O =~ /MSWin32|cygwin|dos|os2/;

mkdir "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"
    or die "Couldn't create directory corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}: $!"
    unless -d "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}";

plan tests => 3;

subtest utf8 => sub {
    plan tests => 3;

    opendir my $dh, 'corpus'
        or die "Couldn't open directory 'corpus'";

    my @files = sort grep { $_ ne '.' and $_ ne '..' } readdir $dh;
    my @utf8_files;
    {
        rewinddir $dh;
        use utf8::all;
        @utf8_files = sort grep { $_ ne '.' and $_ ne '..' } readdir $dh;
    }
    closedir $dh;

    is_deeply \@utf8_files, [sort "\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "testfile"];
    is   $files[0] => $utf8_files[0];
    isnt $files[1] => $utf8_files[1];
};

subtest context => sub {
    plan tests => 1;

    opendir my $dh, 'corpus'
        or die "Couldn't open directory 'corpus'";

    use utf8::all;
    my $core = CORE::readdir $dh;
    rewinddir $dh;
    my $utf8 = readdir $dh;
    rewinddir $dh;

    is $utf8 => decode('UTF-8', $core, FB_CROAK) or diag "$utf8 : $core";
    closedir $dh;
};

subtest package_var => sub {
    plan tests => 3;
    opendir DH, 'corpus'
        or die "Couldn't open directory 'corpus'";

    my @files = sort grep { $_ ne '.' and $_ ne '..' } eval { readdir DH; };
    my @utf8_files;
    {
        rewinddir DH;
        use utf8::all;
        @utf8_files = sort grep { $_ ne '.' and $_ ne '..' } readdir DH;
    }
    closedir DH;

    is_deeply \@utf8_files, [sort "\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "testfile"];
    is $files[0] => $utf8_files[0];
    is decode('UTF-8', $files[1], FB_CROAK) => $utf8_files[1];
};
