use strict;
use warnings;
use Test::More 0.96 tests => 2;
use File::Find;
use Encode qw/decode FB_CROAK/;

subtest utf8find => sub {
    plan tests => 5;

    my @files;
    File::Find::find( { no_chdir => 0, wanted => sub { push(@files, $_) if $_ !~ /\.{1,2}/ } }, 'corpus');
    @files = sort @files;

    my @utf8_files;
    {
        use utf8::all;
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
        use utf8::all;
        File::Find::finddepth( { no_chdir => 0, wanted => sub { push(@utf8_files, $_)  if $_ !~ /\.{1,2}/ } }, 'corpus');
        @utf8_files = sort @utf8_files;
    }

    is_deeply \@utf8_files, [sort "\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "bar", "testfile"];
    is   $files[0] => $utf8_files[0];
    is   $files[1] => $utf8_files[1];
    isnt $files[2] => $utf8_files[2];
    is   decode('UTF-8', $files[2], FB_CROAK) => $utf8_files[2];
};
