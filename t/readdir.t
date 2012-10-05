use strict;
use warnings;
use Test::More tests => 3;

opendir my $dh, 'corpus'
    or die "Couldn't open directory 'corpus'";

my @files =  grep { $_ ne '.' and $_ ne '..' } readdir $dh;
my @utf8_files;
{
    rewinddir $dh;
    use utf8::all;
    @utf8_files = grep { $_ ne '.' and $_ ne '..' } readdir $dh;
}
closedir $dh;

is_deeply \@utf8_files, ["\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "testfile"];
isnt $files[0] => $utf8_files[0];
is   $files[1] => $utf8_files[1];