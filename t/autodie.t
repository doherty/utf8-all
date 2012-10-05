use strict;
use warnings;
use version 0.77;
use Test::More 0.96;
use Test::Fatal;

if ( eval { require autodie; 1 } ) {
    plan skip_all => "autodie is version $autodie::VERSION, but must be greater than version 2.11"
        if (version->parse($autodie::VERSION) < version->parse(2.11));
    plan tests => 2;
}
else {
    plan skip_all => "autodie is required for these tests";
}
no autodie;

subtest 'autodie first' => sub {
    plan tests => 2;
    use autodie;
    use utf8::all;

    opendir my $dh, 'corpus';
    my @files =  grep { !m{^\.} } readdir $dh;
    closedir $dh;

    is_deeply \@files, ["\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "testfile"];

    my $exception = exception { opendir my $no_dh, 'nonexistent' };
    like $exception => qr/No such file or directory/;
};

subtest 'autodie last' => sub {
    plan tests => 2;
    use utf8::all;
    use autodie;

    opendir my $dh, 'corpus';
    my @files =  grep { !m{^\.} } readdir $dh;
    closedir $dh;

    is_deeply \@files, ["\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "testfile"];

    my $exception = exception { opendir my $no_dh, 'nonexistent' };
    like $exception, qr/No such file or directory/;
};
