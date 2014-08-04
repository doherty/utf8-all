package utf8::all;

use strict;
use warnings;
use 5.010; # state

=head1 SYNOPSIS

    use utf8::all; # Turn on UTF-8. All of it.
    use utf8::all qw(noglob); # Turn on UTF-8, except for the glob function.

    open my $in, '<', 'contains-utf8';  # UTF-8 already turned on here
    print length 'føø bār';             # 7 UTF-8 characters
    my $utf8_arg = shift @ARGV;         # @ARGV is UTF-8 too (only for main)

=head1 DESCRIPTION

L<utf8> allows you to write your Perl encoded in UTF-8. That means
UTF-8 strings, variable names, and regular expressions. C<utf8::all>
goes further, and makes C<@ARGV> encoded in UTF-8 (when C<utf8::all>
is used from the main package), and filehandles are opened with UTF-8
encoding turned on by default (including STDIN, STDOUT, STDERR), and
charnames are imported so C<\N{...}> sequences can be used to compile
Unicode characters based on names. If you I<don't> want UTF-8 for a
particular filehandle, you'll have to set C<binmode $filehandle>.

Also redefines the following functions to be UTF-8 aware:

=over

=item

readdir

You can prevent the redefinition of this function by supplying the optional argument C<noreaddir> to the C<use utf8::all> statement.

=item

glob and the < > glob operator

You can prevent the redefinition of this function by supplying the optional argument C<noglob> to the C<use utf8::all> statement.

=item

L<File::Find::find> and L<File::Find::finddepth>

You can prevent the redefinition of these functions by supplying the optional argument C<nofind> to the C<use utf8::all> statement.

=item

L<Cwd::cwd>, L<Cwd::fastcwd>, L<Cwd::getcwd>, L<Cwd::fastgetcwd>

You can prevent the redefinition of these functions by supplying the optional argument C<nocwd> to the C<use utf8::all> statement.

=item

L<Cwd::abs_path>, L<Cwd::realpath>, L<Cwd::fast_abs_path>

You can prevent the redefinition of these functions by supplying the optional argument C<nocwd> to the C<use utf8::all> statement.

=back

B<Note:> None of these functions is redefined on windows as the file
system does not support UTF-8 filenames!

B<Note:> Even if a function has been redefined, it behaves
as normal (non UTF-8 wrapped) when called from within a module that did not
load utf8::all/redefine the function.

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

use Import::Into;

use parent qw(Encode charnames utf8 open warnings feature);
use Symbol qw(qualify_to_ref);

# Holds the pointers to the original version of redefined functions
state %_org_functions;

sub import {
    # Check and set options
    my %options;
    shift; # First entry in @_ is always the package name itself
    map { die qq(Invalid option "$_" to utf8::all) if $_ !~ /^no(cwd|find|readdir|glob)$/i; $options{lc($_)} = 1 } @_;

    # Enable features/pragmas in calling package
    my $target = caller;
    'utf8'->import::into($target);
    'open'->import::into($target, qw{:encoding(UTF-8) :std});
    'charnames'->import::into($target, qw{:full :short});
    'warnings'->import::into($target, qw{FATAL utf8});
    'feature'->import::into($target, qw{unicode_strings}) if $^V >= v5.11.0;
    'feature'->import::into($target, qw{unicode_eval fc}) if $^V >= v5.16.0;

    unless ($^O eq 'Win32') {
        no strict qw(refs); ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no warnings qw(redefine);

        # Replace readdir with utf8 aware version
        if (!$options{noreaddir}) {
            *{$target . '::readdir'} = \&_utf8_readdir;
            $^H{'utf8::all::readdir'} = 1; # Set hint so we know in the redefined function we have to encode/decode
        }

        # Replace glob with utf8 aware version
        if (!$options{noglob}) {
            *{$target . '::glob'} = \&_utf8_glob;
            $^H{'utf8::all::glob'} = 1; # Set hint so we know in the redefined function we have to encode/decode
        }

        # List of redefined non-core functions
        my @redefined;

        if (!$options{nocwd}) {
            require Cwd unless $options{nocwd};
            push @redefined, qw(Cwd::cwd Cwd::fastcwd Cwd::getcwd Cwd::fastgetcwd Cwd::abs_path Cwd::realpath Cwd::fast_abs_path);
        }

        if (!$options{nofind}) {
            require File::Find unless $options{nofind};
            push @redefined, qw(File::Find::find File::Find::finddepth);
        }

        for my $f (@redefined) {
            $^H{"utf8::all::$f"} = 1; # Set hint so we know in the redefined functions we have to encode/decode
            # If we already have the _org_function, we have redefined the function
            # in an earlier load of the module, so we need not do it again
            if (!$_org_functions{$f}) {
                $_org_functions{$f} = \&{$f};
                if ($f =~ /^File::Find::(find|finddepth)$/) {
                    *{$f} = \&{"_utf8_$1"};
                } else {
                    *{$f} = sub { return _utf8_simple_func($f, @_); };
                }
            }
        }
    }

    # Make @ARGV utf-8 when called from the main package
    state $have_encoded_argv = 0;
    map { $_ = Encode::decode('UTF-8' ,$_) } @ARGV if $target eq "main" && !$have_encoded_argv++;

    return;
}

sub _utf8_simple_func {
    my $func = shift;
    my $hints = (caller 1)[10]; # Use caller level 1 because of the added anonymous sub around call
    if (not $hints->{"utf8::all::$func"}) {
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
    if (not $hints->{'utf8::all::readdir'}) {
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

sub _utf8_find {
    my $ref = shift; # This can be the wanted function or a find options hash
    #  Make argument always into the find's options hash
    my %find_options_hash = ref($ref) eq "HASH" ? %$ref : (wanted => $ref);
    my $wanted = $find_options_hash{wanted}; # The original wanted function
    # Get the hint from the caller (one level deeper if called from _utf8_finddepth)
    my $hints = ((caller 1)[3]//"") ne 'utf8::all::_utf8_finddepth' ? (caller 0)[10] : (caller 1)[10];
    if (not $hints->{'utf8::all::File::Find::find'}) {
        return $_org_functions{"File::Find::find"}->(\%find_options_hash, @_);
    } else {
        $find_options_hash{wanted} = sub {
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
        return $_org_functions{"File::Find::find"}->(\%find_options_hash, map { Encode::encode('UTF-8', $_) } @_);
    }
}

sub _utf8_finddepth {
    my $ref = shift; # This can be the wanted function or a find options hash
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
