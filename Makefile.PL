
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;
check_conflicts();



my %WriteMakefileArgs = (
  "ABSTRACT" => "turn on Unicode - all of it",
  "AUTHOR" => "Michael Schwern <mschwern\@cpan.org>, Mike Doherty <doherty\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
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
    "Symbol" => 0,
    "charnames" => 0,
    "feature" => 0,
    "open" => 0,
    "parent" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "PerlIO" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.96",
    "Test::Warn" => 0,
    "autodie" => 0,
    "version" => "0.77"
  },
  "VERSION" => "0.011",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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

    return if $ENV{AUTOMATED_TESTING} || $ENV{NONINTERACTIVE_TESTING};

    # More or less copied from Module::Build
    return if $ENV{PERL_MM_USE_DEFAULT};
    return unless -t STDIN && ( -t STDOUT || !( -f STDOUT || -c STDOUT ) );

    sleep 4;
}
