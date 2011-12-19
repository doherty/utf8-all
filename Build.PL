
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "PerlIO" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "turn on Unicode - all of it",
  "dist_author" => [
    "Michael Schwern <mschwern\@cpan.org>",
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "utf8-all",
  "dist_version" => "v0.3",
  "license" => "perl",
  "module_name" => "utf8::all",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Encode" => 0,
    "charnames" => 0,
    "open" => 0,
    "parent" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
