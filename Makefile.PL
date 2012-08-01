
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;
check_conflicts();



my %WriteMakefileArgs = (
  "ABSTRACT" => "turn on Unicode - all of it",
  "AUTHOR" => "Michael Schwern <mschwern\@cpan.org>, Mike Doherty <doherty\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "PerlIO" => 0,
    "Test::More" => 0,
    "Test::Warn" => 0,
    "autodie" => 0,
    "version" => "0.77"
  },
  "CONFIGURE_REQUIRES" => {
    "Dist::CheckConflicts" => "0.02",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "utf8-all",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "utf8::all",
  "PREREQ_PM" => {
    "Dist::CheckConflicts" => "0.02",
    "Encode" => 0,
    "Import::Into" => 0,
    "charnames" => 0,
    "open" => 0,
    "parent" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.007",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);




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
