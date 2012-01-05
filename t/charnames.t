#!perl
# Test that utf8::all imports charnames for \N

use utf8::all;
use Test::More tests => 3;

is_deeply "\N{GREEK SMALL LETTER SIGMA} is called sigma.",
          "σ is called sigma.",
          ':full';

is_deeply "\N{greek:Sigma}",
          "Σ",
          ':short';

is_deeply charnames::vianame("GOTHIC LETTER AHSA"),
          66352,
          'charnames::vianame';
