use strict;
use warnings;
use Test::More tests => 1;

if ( eval { require autodie; 1 } ) {
    ok $autodie::VERSION > 2.11
        or diag "autodie is version $autodie::VERSION, but must be greater than version 2.11";
}
else {
    pass;
}
