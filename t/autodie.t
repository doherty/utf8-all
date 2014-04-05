use strict;
use warnings;
use version 0.77;
use Test::More 0.96;
use Test::Fatal;

if ( eval { require autodie; 1 } ) {
    BAIL_OUT <<END_WHY
autodie is version $autodie::VERSION, but must be greater than version 2.11.
Please see the warning in the utf8::all documentation, and upgrade autodie to
at least version 2.12.
END_WHY
        if version->parse($autodie::VERSION) <= version->parse(2.11);
    plan tests => 2;
}
else {
    plan skip_all => "autodie is required for these tests (but is not a prerequisite)";
}
no autodie;

subtest 'autodie first' => sub {
    plan tests => 2;
    use autodie;
    use utf8::all;

    opendir my $dh, 'corpus';
    my @files =  sort grep { !m{^\.} } readdir $dh;
    closedir $dh;

    is_deeply \@files, [sort "\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "testfile"];

    my $exception = exception { opendir my $no_dh, 'nonexistent' };
    like $exception => qr/^\QCan't opendir/;
};

subtest 'autodie last' => sub {
    plan tests => 2;
    use utf8::all;
    use autodie;

    opendir my $dh, 'corpus';
    my @files = sort grep { !m{^\.} } readdir $dh;
    closedir $dh;

    is_deeply \@files, [ sort "\x{307f}\x{304b}\x{3061}\x{3083}\x{3093}", "testfile"];

    my $exception = exception { opendir my $no_dh, 'nonexistent' };
    like $exception, qr/^\QCan't opendir/;
};
