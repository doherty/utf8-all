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

plan tests => 1;

subtest glob => sub {
    plan tests => 14;

    my @globs = (glob("corpus/*"), glob("corpus/{testfile,\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}}"), <corpus/*>);
    my $count = 0;
    while (my $glob = glob("corpus/*")) {
        push(@globs, $glob);
        $count++;
    }
    @globs = sort @globs;

    my @utf8_globs;
    my $utf8_count = 0;
    {
        use utf8::all;
        @utf8_globs = (glob("corpus/*"), glob("corpus/{testfile,\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}}"), <corpus/*>);
        while (my $glob = glob("corpus/*")) {
            push(@utf8_globs, $glob);
            $utf8_count++;
        }
    }
    @utf8_globs = sort @utf8_globs;

    is $count => 2, "glob: scalar version";
    is $utf8_count => 2, "utf8_glob: scalar version";

    for (my $i=0; $i<4; $i++) {
        is   $globs[$i] => $utf8_globs[$i];
        isnt $globs[4+$i] => $utf8_globs[4+$i];
        is   decode('UTF-8', $globs[4+$i], FB_CROAK) => $utf8_globs[4+$i];
    }
};

