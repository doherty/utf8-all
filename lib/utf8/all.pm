package utf8::all;
use strict;
use warnings;
use 5.010; # state

# ABSTRACT: turn on Unicode - all of it
# VERSION

=head1 SYNOPSIS

    use utf8::all;                      # Turn on UTF-8, all of it.

    open my $in, '<', 'contains-utf8';  # UTF-8 already turned on here
    print length 'føø bār';             # 7 UTF-8 characters
    my $utf8_arg = shift @ARGV;         # @ARGV is UTF-8 too (only for main)

=head1 DESCRIPTION

The C<use utf8> pragma tells the Perl parser to allow UTF-8 in the
program text in the current lexical scope. This also means that you
can now use literal Unicode characters as part of strings, variable
names, and regular expressions.

C<utf8::all> goes further:

=over 4

=item *

L<C<charnames>|charnames> are imported so C<\N{...}> sequences can be
used to compile Unicode characters based on names.

=item *

On Perl C<v5.11.0> or higher, the C<use feature 'unicode_strings'> is
enabled.

=item *

C<use feature fc> and C<use feature unicode_eval> are enabled on Perl
C<5.16.0> and higher.

=item *

Filehandles are opened with UTF-8 encoding turned on by default
(including C<STDIN>, C<STDOUT>, and C<STDERR> when C<utf8::all> is
used from the C<main> package). Meaning that they automatically
convert UTF-8 octets to characters and vice versa. If you I<don't>
want UTF-8 for a particular filehandle, you'll have to set C<binmode
$filehandle>.

=item *

C<@ARGV> gets converted from UTF-8 octets to Unicode characters (when
C<utf8::all> is used from the C<main> package). This is similar to the
behaviour of the C<-CA> perl command-line switch (see L<perlrun>).


=item *

C<%ENV> gets tied to a C<Tie::StdHash> based object that decodes UTF-8 
in Environment Variables to Unicode characters.

=item *

C<readdir>, C<readlink>, C<readpipe> (including the C<qx//> and
backtick operators), and L<C<glob>|perlfunc/glob> (including the C<<
<> >> operator) now all work with and return Unicode characters
instead of (UTF-8) octets (again only when C<utf8::all> is used from
the C<main> package).

=back

=head2 Lexical Scope

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

Instead of lexical scoping, you can also use C<no utf8::all> to turn
off the effects.

Note that the effect on C<@ARGV> and the C<STDIN>, C<STDOUT>, and
C<STDERR> file handles is always global and can not be undone!

=head2 Enabling/Disabling Global Features

As described above, the default behaviour of C<utf8::all> is to
convert C<@ARGV> and to open the C<STDIN>, C<STDOUT>, and 
C<STDERR> file handles with UTF-8 encoding, and override the C<readlink> and
C<readdir> functions and C<glob> operatorsi, and tie C<%ENV> to handle UTF-8 in
Environment variables when C<utf8::all> is used from the C<main> package.

If you want to disable these features even when C<utf8::all> is used
from the C<main> package, add the option C<NO-GLOBAL> (or
C<LEXICAL-ONLY>) to the use line. E.g.:

    use utf8::all 'NO-GLOBAL';

If on the other hand you want to enable these global effects even when
C<utf8::all> was used from another package than C<main>, use the
option C<GLOBAL> on the use line:

    use utf8::all 'GLOBAL';

=head2 UTF-8 Errors

C<utf8::all> will handle invalid code points (i.e., utf-8 that does
not map to a valid unicode "character"), as a fatal error.

For C<glob>, C<readdir>, and C<readlink>, one can change this
behaviour by setting the attribute L</"$utf8::all::UTF8_CHECK">.

=head1 COMPATIBILITY

The filesystems of Dos, Windows, and OS/2 do not (fully) support
UTF-8. The C<readlink> and C<readdir> functions and C<glob> operators
will therefore not be replaced on these systems.

=head1 SEE ALSO

=over 4

=item *

L<File::Find::utf8> for fully utf-8 aware File::Find functions.

=item *

L<Cwd::utf8> for fully utf-8 aware Cwd functions.

=back

=cut

use Import::Into;
use parent qw(Encode charnames utf8 open warnings feature);
use Symbol qw(qualify_to_ref);
use Config;

# Holds the pointers to the original version of redefined functions
state %_orig_functions;

# Current (i.e., this) package
my $current_package = __PACKAGE__;

require Carp;
$Carp::Internal{$current_package}++; # To get warnings reported at correct caller level

=attr $utf8::all::UTF8_CHECK

By default C<utf8::all> marks decoding errors as fatal (default value
for this setting is C<Encode::FB_CROAK>). If you want, you can change this by
setting C<$utf8::all::UTF8_CHECK>. The value C<Encode::FB_WARN> reports
the encoding errors as warnings, and C<Encode::FB_DEFAULT> will completely
ignore them. Please see L<Encode> for details. Note: C<Encode::LEAVE_SRC> is
I<always> enforced.

Important: Only controls the handling of decoding errors in C<glob>,
C<readdir>, and C<readlink>.

=cut

use Encode ();
use PerlIO::utf8_strict;

our $UTF8_CHECK = Encode::FB_CROAK | Encode::LEAVE_SRC; # Die on encoding errors

# UTF-8 Encoding object
my $_UTF8 = Encode::find_encoding('UTF-8');

sub import {
    # Enable features/pragmas in calling package
    my $target = caller;

    # Enable global effects be default only when imported from main package
    my $no_global = $target ne 'main';

    # Override global?
    if (defined $_[1] && $_[1] =~ /^(?:(NO-)?GLOBAL|LEXICAL-ONLY)$/i) {
        $no_global = $_[1] !~ /^GLOBAL$/i;
        splice(@_, 1, 1); # Remove option from import's arguments
    }

    'utf8'->import::into($target);
    'open'->import::into($target, 'IO' => ':utf8_strict');

    # use open ':std' only works with some encodings.
    state $have_encoded_std = 0;
    unless ($no_global || $have_encoded_std++) {
        binmode STDERR, ':utf8_strict';
        binmode STDOUT, ':utf8_strict';
        binmode STDIN,  ':utf8_strict';
    }

    'charnames'->import::into($target, qw{:full :short});
    'warnings'->import::into($target, qw{FATAL utf8});
    'feature'->import::into($target, qw{unicode_strings}) if $^V >= v5.11.0;
    'feature'->import::into($target, qw{unicode_eval fc}) if $^V >= v5.16.0;

    unless ($no_global || $^O =~ /MSWin32|cygwin|dos|os2/) {
        no strict qw(refs); ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no warnings qw(redefine);

        # Replace readdir with utf8 aware version
        *{$target . '::readdir'} = \&_utf8_readdir;

        # Replace readdir with utf8 aware version
        *{$target . '::readlink'} = \&_utf8_readlink;

        # Replace glob with utf8 aware version
        *{$target . '::glob'} = \&_utf8_glob;

        # Set compiler hint to encode/decode in the redefined functions
        $^H{'utf8::all'} = 1;
    }

    # Make @ARGV utf-8 when, unless perl was launched with the -CA
    # flag as this already has @ARGV decoded automatically.  -CA is
    # active if the the fifth bit (32) of the ${^UNICODE} variable is
    # set.  (see perlrun on the -C command switch for details about
    # ${^UNICODE})
    unless ($no_global || (${^UNICODE} & 32)) {
        state $have_encoded_argv = 0;
        if (!$have_encoded_argv++) {
            $UTF8_CHECK |= Encode::LEAVE_SRC if $UTF8_CHECK; # Enforce LEAVE_SRC
            $_ = ($_ ? $_UTF8->decode($_, $UTF8_CHECK) : $_) for @ARGV;
        }
    }


	#Parse %ENV and decode any UTF-8 byte strings.
	unless ($no_global) {
		tie %ENV, "utf8::all::TieENV", %ENV;
	}


    return;
}

sub unimport { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    # Disable features/pragmas in calling package
    # Note: Does NOT undo the effect on @ARGV,
    #       nor on the STDIN, STDOUT, and STDERR file handles!
    #       These effects are always "global".

    my $target = caller;
    'utf8'->unimport::out_of($target);
    'open'->import::into($target, qw{IO :bytes});

    unless ($^O =~ /MSWin32|cygwin|dos|os2/) {
        $^H{'utf8::all'} = 0; # Reset compiler hint
    }

    return;
}

sub _utf8_readdir(*) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my $pre_handle = shift;
    my $hints = (caller 0)[10];
   my $handle = ref($pre_handle) ? $pre_handle : qualify_to_ref($pre_handle, caller);
    if (not $hints->{'utf8::all'}) {
        return CORE::readdir($handle);
    } else {
        $UTF8_CHECK |= Encode::LEAVE_SRC if $UTF8_CHECK; # Enforce LEAVE_SRC
        if (wantarray) {
            return map { $_ ? $_UTF8->decode($_, $UTF8_CHECK) : $_ } CORE::readdir($handle);
        } else {
            my $r = CORE::readdir($handle);
            return $r ? $_UTF8->decode($r, $UTF8_CHECK) : $r;
        }
    }
}

sub _utf8_readlink(_) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my $arg = shift;
    my $hints = (caller 0)[10];
    if (not $hints->{'utf8::all'}) {
        return CORE::readlink($arg);
    } else {
        $UTF8_CHECK |= Encode::LEAVE_SRC if $UTF8_CHECK; # Enforce LEAVE_SRC
        $arg = $arg ? $_UTF8->encode($arg, $UTF8_CHECK) : $arg;
        my $r = CORE::readlink($arg);
        return $r ? $_UTF8->decode($r, $UTF8_CHECK) : $r;
    }
}

sub _utf8_glob {
    my $arg = $_[0]; # Making this a lexical somehow is important!
    my $hints = (caller 0)[10];
    if (not $hints->{'utf8::all'}) {
        return CORE::glob($arg);
    } else {
        $UTF8_CHECK |= Encode::LEAVE_SRC if $UTF8_CHECK; # Enforce LEAVE_SRC
        $arg = $arg ? $_UTF8->encode($arg, $UTF8_CHECK) : $arg;
        if (wantarray) {
            return map { $_ ? $_UTF8->decode($_, $UTF8_CHECK) : $_ } CORE::glob($arg);
        } else {
            my $r = CORE::glob($arg);
            return $r ? $_UTF8->decode($r, $UTF8_CHECK) : $r;
        }
    }
}

=head1 INTERACTION WITH AUTODIE

If you use L<autodie>, which is a great idea, you need to use at least
version B<2.12>, released on L<June 26,
2012|https://metacpan.org/source/PJF/autodie-2.12/Changes#L3>.
Otherwise, autodie obliterates the IO layers set by the L<open>
pragma. See L<RT
#54777|https://rt.cpan.org/Ticket/Display.html?id=54777> and L<GH
#7|https://github.com/doherty/utf8-all/issues/7>.

=cut


package utf8::all::TieENV;

use strict;
use warnings;
use Tie::Hash;
use base 'Tie::StdHash';

sub TIEHASH {
	my $class = shift;
	my $self = bless {}, $class;
	while( my ($k, $v) = splice @_, 0, 2 ) {
		$self->{$k} = $v;
	}

	return $self;
}

sub FETCH {
	my $self = shift;
	my $value = $self->SUPER::FETCH(@_);
	return $value ? $_UTF8->decode($value, $utf8::all::UTF8_CHECK) : $value;
}
1;
