################################################################################
#
# Module to turns on UTF-8 for everything:
# * Enables utf8 and related features
# * Imports charnames (\N{...})
# * Specifies all IO (except DATA) to be in UTF-8
# * Decodes @ARGV as UTF-8, when loaded from the main package
# * Redefines frequently used functions to be fully UTF-8 compatible:
#   - readdir,
#   - File::Find::find, File::Find::finddepth,
#   - Cwd::cwd Cwd::fastcwd Cwd::getcwd Cwd::fastgetcwd
#   - Cwd::abs_path Cwd::realpath Cwd::fast_abs_path
#
################################################################################

package utf8::all;

use strict;
use warnings;
use 5.010; # state
use utf8;

our $VERSION = "0.012";

################################################################################

=encoding utf-8

=head1 SYNOPSIS

    use utf8::all; # Turn on UTF-8. All of it.

    open my $in, '<', 'contains-utf8';  # UTF-8 already turned on here
    print length 'føø bār';             # 7 UTF-8 characters
    my $utf8_arg = shift @ARGV;         # @ARGV is UTF-8 too (only for main!)

=head1 DESCRIPTION

L<utf8> allows you to write your Perl encoded in UTF-8. That means
UTF-8 strings, variable names, and regular expressions. C<utf8::all>
goes further, and makes C<@ARGV> encoded in UTF-8 (when C<utf8::all>
is used from the main package), and filehandles are opened with UTF-8
encoding turned on by default (including STDIN, STDOUT, STDERR), and
charnames are imported so C<\N{...}> sequences can be used to compile
Unicode characters based on names. If you I<don't> want UTF-8 for a
particular filehandle, you'll have to set C<binmode $filehandle>.

Also redefines the core readdir function, File::Find::find,
File::Find::finddepth, and the Cwd:: functions so they are fully UTF-8
aware too.

The pragma is lexically-scoped, so you can do the following if you had
some reason to:

    {
        use utf8::all;
        open my $out, '>', 'outfile';
        my $utf8_str = 'føø bār';
        print length $utf8_str, "\n"; # 7
        print $out $utf8_str;         # out as utf8
    }
    open my $in, '<', 'outfile';      # in as raw
    my $text = do { local $/; <$in>};
    print length $text, "\n";         # 10, not 7!

=cut


################################################################################

use Import::Into;

use parent qw(Encode charnames utf8 open warnings feature);
use Symbol qw(qualify_to_ref);

use File::Find ();
use Cwd ();

# Holds the pointers to the original version of redefined functions
my %_org_functions;

# List of redefined "simple" functions; string arguments and (list of) string returns.
my @_redefined_simple = qw(Cwd::cwd Cwd::fastcwd Cwd::getcwd Cwd::fastgetcwd Cwd::abs_path Cwd::realpath Cwd::fast_abs_path);

# All redefined (non-core) functions
my @_redefined = (@_redefined_simple, qw(File::Find::find File::Find::finddepth));

sub import {
    # Enable features/pragmas in calling package
    my $target = caller;
    'utf8'->import::into($target);
    'open'->import::into($target, qw{:encoding(UTF-8) :std});
    'charnames'->import::into($target, qw{:full :short});
    'warnings'->import::into($target);
    'warnings'->import::into($target, qw{FATAL utf8});
    'feature'->import::into($target, qw{unicode_strings}) if $^V >= v5.11.0;
    'feature'->import::into($target, qw{unicode_eval fc}) if $^V >= v5.16.0;

    {
        no strict qw(refs); ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no warnings qw(redefine);

        # Replace readdir with utf8 aware version
        *{$target . '::readdir'} = \&_utf8_readdir;

        # Replace glob with utf8 aware version
        *{$target . '::glob'} = \&_utf8_glob;

        # Redefine find functions to be fully utf8 aware
        state $have_redefined;
        if (!$have_redefined++) {
            map { $_org_functions{$_} = \&{$_}; } @_redefined;

            for my $f (@_redefined_simple) { 
                *{$f} = sub { return _utf8_simple_func($f, @_); };
            }
            *File::Find::find      = \&_utf8_find;
            *File::Find::finddepth = \&_utf8_finddepth;
        }
    }

    # Make @ARGV utf-8 when called from the main package
    state $have_encoded_argv = 0;
    map { $_ = Encode::decode('UTF-8' ,$_) } @ARGV unless $target ne "main" || $have_encoded_argv++;

    $^H{'utf8::all'} = 1; # Set hint so we know in the redefined functions we have to encode/decode

    return;
}

sub _utf8_simple_func {
    my $func = shift;
    my $hints = (caller 1)[10]; # Use caller level 1 because of the added anonymous sub around call
    if (not $hints->{'utf8::all'}) {
        return $_org_functions{$func}->(@_);
    } elsif (wantarray) {
        return map { Encode::decode('UTF-8' ,$_) } $_org_functions{$func}->(map { Encode::encode('UTF-8', $_) } @_);
    } else {
        return Encode::decode('UTF-8', $_org_functions{$func}->(map { Encode::encode('UTF-8', $_) } @_));
    }
}

sub _utf8_readdir(*) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my $pre_handle = shift;
    my $handle = ref($pre_handle) ? $pre_handle : qualify_to_ref($pre_handle, caller);
    my $hints = (caller 0)[10];
    if (not $hints->{'utf8::all'}) {
        return CORE::readdir($handle);
    } elsif (wantarray) {
        return map { Encode::decode('UTF-8' ,$_) } CORE::readdir($handle);
    } else {
        return Encode::decode('UTF-8', CORE::readdir($handle));
    }
}

sub _utf8_glob {
    my $arg = $_[0]; # Making this a lexical somehow is important!
    my $hints = (caller 0)[10];
    if (not $hints->{'utf8::all'}) {
        return CORE::glob($arg);
    } else {
        $arg = Encode::encode('UTF-8', $arg);
        if (wantarray) {
            return map { Encode::decode('UTF-8' ,$_) } CORE::glob($arg);
        } else {
            return Encode::decode('UTF-8', CORE::glob($arg));
        }
    }
}

sub _utf8_find {
    my $ref = shift; # Wanted function or options hash
    my %findoptionshash = ref($ref) eq "HASH" ? %$ref : ();
    my $wanted = ref($ref) eq "HASH" ? $ref->{wanted} : $ref;
    my $hints = ((caller 1)[3]//"") ne 'utf8::all::_utf8_finddepth' ? (caller 0)[10] : (caller 1)[10];
    if (not $hints->{'utf8::all'}) {
        return $_org_functions{"File::Find::find"}->(\%findoptionshash, @_);
    } else {
        $findoptionshash{wanted} = sub {
            # Decode the file variables
            local $_                    = Encode::decode('UTF-8', $_);
            local $File::Find::name     = Encode::decode('UTF-8', $File::Find::name);
            local $File::Find::dir      = Encode::decode('UTF-8', $File::Find::dir);
            local $File::Find::fullname = Encode::decode('UTF-8', $File::Find::fullname);
            local $File::Find::topdir   = Encode::decode('UTF-8', $File::Find::topdir);
            local $File::Find::topdev   = Encode::decode('UTF-8', $File::Find::topdev);
            local $File::Find::topino   = Encode::decode('UTF-8', $File::Find::topino);
            local $File::Find::topmode  = Encode::decode('UTF-8', $File::Find::topmode);
            local $File::Find::topnlink = Encode::decode('UTF-8', $File::Find::topnlink);
            $wanted->();
        };
        return $_org_functions{"File::Find::find"}->(\%findoptionshash, map { Encode::encode('UTF-8', $_) } @_);
    }
}

sub _utf8_finddepth {
    my $ref = shift; # Wanted function or options hash
    my $hints = (caller 0)[10];
    my $i=0;
    return _utf8_find( { bydepth => 1, ref($ref) eq "HASH" ? %$ref : (wanted => $ref) }, @_);
}


=head1 INTERACTION WITH AUTODIE

If you use L<autodie>, which is a great idea, you need to use at least version
B<2.12>, released on L<June 26, 2012|https://metacpan.org/source/PJF/autodie-2.12/Changes#L3>.
Otherwise, autodie obliterates the IO layers set by the L<open> pragma. See
L<RT #54777|https://rt.cpan.org/Ticket/Display.html?id=54777> and
L<GH #7|https://github.com/doherty/utf8-all/issues/7>.

=cut

1;

__END__
