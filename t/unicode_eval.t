#!perl
# utf8::all should turn on feature qw(unicode_strings)

use strict;
use warnings;
use Test::More;
plan $^V >= v5.16.0
    ? (tests => 5)
    : (skip_all => q/Can't enable unicode_eval on perl < 5.16.0/);

# straight out of t/uni/eval.t
use utf8::all;

{
    my $w;
    $SIG{__WARN__} = sub { $w = shift };
    use utf8;
    my $prog = "qq!\x{f9}!";

    eval $prog;
    ok !$w;

    $w = "";
    utf8::upgrade($prog);
    eval $prog;
    is $w, '';
}

{
    use utf8;
    isnt eval "q!\360\237\220\252!", eval "q!\x{1f42a}!";
}

{
    no utf8; #Let's make real sure.
    my $not_utf8 = "q!\343\203\213!";
    isnt eval $not_utf8, eval "q!\x{30cb}!";
    {
        use utf8;
        isnt eval $not_utf8, eval "q!\x{30cb}!";
    }
}