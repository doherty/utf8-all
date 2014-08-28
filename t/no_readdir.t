#!perl
use strict;
use warnings;
use Test::More 0.96;
use Encode qw/encode FB_CROAK/;

plan skip_all => q/Can't Unicodify readdir on Windows/
    if $^O eq 'Win32';

mkdir "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"
    or die "Couldn't create directory corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}: $!"
    unless -d "corpus/\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}";

plan tests => 1;

subtest utf8 => sub {
    plan tests => 3;

    opendir my $dh, 'corpus'
        or die "Couldn't open directory 'corpus'";

    my @files = sort grep { $_ ne '.' and $_ ne '..' } readdir $dh;
    my @utf8_files;
    {
        rewinddir $dh;
        use utf8::all qw(no_readdir);
        @utf8_files = sort grep { $_ ne '.' and $_ ne '..' } readdir $dh;
    }
    closedir $dh;

    is_deeply \@utf8_files, [sort (encode('UTF-8', "\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}"), "testfile")];
    is   $files[0] => $utf8_files[0];
    is   $files[1] => $utf8_files[1];
};
