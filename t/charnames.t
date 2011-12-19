#!perl
# Test that utf8::all imports charnames for \N

use utf8::all;
use Test::More tests => 3;

is_deeply "\N{GREEK SMALL LETTER SIGMA} is called sigma.",
          "σ is called sigma.";

is_deeply "\N{LATIN CAPITAL LETTER E WITH VERTICAL LINE BELOW}",
          "E̩";

is_deeply charnames::vianame("GOTHIC LETTER AHSA"),
          66352;

