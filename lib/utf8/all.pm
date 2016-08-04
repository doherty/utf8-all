package utf8::all;
use strict;
use warnings;
use 5.010; # state

# ABSTRACT: turn on Unicode - all of it
# VERSION

=encoding utf8
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
(including STDIN, STDOUT, STDERR). Meaning that they automatically
convert UTF-8 octets to characters and vice versa. If you I<don't>
want UTF-8 for a particular filehandle, you'll have to set C<binmode
$filehandle>.

=item *

C<@ARGV> gets converted from UTF-8 octets to Unicode characters (when
C<utf8::all> is used from the main package). This is similar to the
behaviour of the C<-CA> perl command-line switch (see L<perlrun>).

=item *

C<readdir>, C<readlink>, C<readpipe> (including the C<qx//> and
backtick operators), and L<C<glob>|perlfunc/glob> (including the C<< <>
>> operator) now all work with and return Unicode characters instead
of (UTF-8) octets.

=back

=head2 Lexical scope

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
C<STDERR> file handles is always global!

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

# Holds the pointers to the original version of redefined functions
state %_orig_functions;

sub import {
    # Enable features/pragmas in calling package
    my $target = caller;
    'utf8'->import::into($target);
    'open'->import::into($target, qw{:encoding(UTF-8) :std});
    'charnames'->import::into($target, qw{:full :short});
    'warnings'->import::into($target, qw{FATAL utf8});
    'feature'->import::into($target, qw{unicode_strings}) if $^V >= v5.11.0;
    'feature'->import::into($target, qw{unicode_eval fc}) if $^V >= v5.16.0;

    unless ($^O =~ /MSWin32|cygwin|dos|os2/) {
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

    # Make @ARGV utf-8 when called from the main package, unless perl was launched
    # with the -CA flag as this already has @ARGV decoded automatically.
    # -CA is active if the the fifth bit (32) of the ${^UNICODE} variable is set.
    # (see perlrun on the -C command switch for details about ${^UNICODE})
    if (!(${^UNICODE} & 32)) {
        state $have_encoded_argv = 0;
        if ($target eq 'main' && !$have_encoded_argv++) {
            $_ = Encode::decode('UTF-8' ,$_) for @ARGV;
        }
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

    $^H{'utf8::all'} = 0; # Reset compiler hint

    return;
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

sub _utf8_readlink(_) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my $arg = shift;
    my $hints = (caller 0)[10];
    if (not $hints->{'utf8::all'}) {
        return CORE::readlink($arg);
    } else {
        return Encode::decode('UTF-8', CORE::readlink(Encode::encode('UTF-8', $arg)));
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

=head1 INTERACTION WITH AUTODIE

If you use L<autodie>, which is a great idea, you need to use at least version
B<2.12>, released on L<June 26, 2012|https://metacpan.org/source/PJF/autodie-2.12/Changes#L3>.
Otherwise, autodie obliterates the IO layers set by the L<open> pragma. See
L<RT #54777|https://rt.cpan.org/Ticket/Display.html?id=54777> and
L<GH #7|https://github.com/doherty/utf8-all/issues/7>.

=cut

1;
