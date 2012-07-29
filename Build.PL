
use strict;
use warnings;

use Module::Build 0.3601;
check_conflicts();


my %module_build_args = (
  "build_requires" => {
    "Capture::Tiny" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "PerlIO" => 0,
    "Test::More" => 0,
    "autodie" => 0
  },
  "configure_requires" => {
    "Dist::CheckConflicts" => "0.02",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "turn on Unicode - all of it",
  "dist_author" => [
    "Michael Schwern <mschwern\@cpan.org>",
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "utf8-all",
  "dist_version" => "0.006",
  "license" => "perl",
  "module_name" => "utf8::all",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dist::CheckConflicts" => "0.02",
    "Encode" => 0,
    "Import::Into" => 0,
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

sub check_conflicts {
    if ( eval { require 'lib/utf8/all/Conflicts.pm'; 1; } ) {
        if ( eval { utf8::all::Conflicts->check_conflicts; 1 } ) {
            return;
        }
        else {
            my $err = $@;
            $err =~ s/^/    /mg;
            warn "***\n$err***\n";
        }
    }
    else {
        print <<'EOF';
***
    Your toolchain doesn't support configure_requires, so Dist::CheckConflicts
    hasn't been installed yet. You should check for conflicting modules
    manually by examining the list of conflicts in utf8::all::Conflicts once the installation
    finishes.
***
EOF
    }

    # More or less copied from Module::Build
    return if $ENV{PERL_MM_USE_DEFAULT};
    return unless -t STDIN && ( -t STDOUT || !( -f STDOUT || -c STDOUT ) );

    sleep 4;
}
