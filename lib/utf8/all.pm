package utf8::all;
use strict;
use warnings;
use 5.010; # state

# ABSTRACT: turn on Unicode - all of it
# VERSION

=head1 SYNOPSIS

    use utf8::all;                # Turn on UTF-8, all of it.

    open my $in, '<', 'contains-utf8';  # UTF-8 already turned on here
    print length 'føø bār';             # 7 UTF-8 characters
    my $utf8_arg = shift @ARGV;         # @ARGV is UTF-8 too (only for main)

=head1 DESCRIPTION

L<utf8> allows you to write your Perl encoded in UTF-8. That means
UTF-8 strings, variable names, and regular expressions.

C<utf8::all> goes further:

=over 4

=item *

Makes C<@ARGV> encoded in UTF-8 (when C<utf8::all> is used from the main package).

=item *

Filehandles are opened with UTF-8 encoding turned on by default
(including STDIN, STDOUT, STDERR). If you I<don't> want UTF-8 for a
particular filehandle, you'll have to set C<binmode $filehandle>.

=item *

L<charnames> are imported so C<\N{...}> sequences can be used to compile
Unicode characters based on names.

=item *

C<readdir> now returns UTF-8 characters instead of bytes.

=item *

C<readlink> now returns UTF-8 characters instead of bytes.

=item *

L<C<glob>|perlfunc/glob> and the C<< <> >> operator now return UTF-8
characters instead of bytes.

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

=head1 COMPATIBILITY

The filesystems of Dos, Windows, and OS/2 do not (fully) support
UTF-8. The C<readdir> function and C<glob> operators will therefore not
be replaced on these systems.

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
        $^H{'utf8::all::readdir'} = 1; # Track whether to encode/decode in the redefined function

        # Replace readdir with utf8 aware version
        *{$target . '::readlink'} = \&_utf8_readlink;
        $^H{'utf8::all::readlink'} = 1; # Track whether to encode/decode in the redefined function

        # Replace glob with utf8 aware version
        *{$target . '::glob'} = \&_utf8_glob;
        $^H{'utf8::all::glob'} = 1;
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

    $^H{'utf8::all'} = 1;

    return;
}

sub _utf8_readdir(*) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my $pre_handle = shift;
    my $handle = ref($pre_handle) ? $pre_handle : qualify_to_ref($pre_handle, caller);
    my $hints = (caller 0)[10];
    if (not $hints->{'utf8::all::readdir'}) {
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
    if (not $hints->{'utf8::all::readlink'}) {
        return CORE::readlink($arg);
    } else {
        return Encode::decode('UTF-8', CORE::readlink(Encode::encode('UTF-8', $arg)));
    }
}

sub _utf8_glob {
    my $arg = $_[0]; # Making this a lexical somehow is important!
    my $hints = (caller 0)[10];
    if (not $hints->{'utf8::all::glob'}) {
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
