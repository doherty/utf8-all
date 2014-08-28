package utf8::all;
use strict;
use warnings;
use 5.010; # state
# ABSTRACT: turn on Unicode - all of it
# VERSION

=head1 SYNOPSIS

    use utf8::all;                # Turn on UTF-8, all of it.

    # Also provide UTF-8 versions of functions from...
    use utf8::all qw(File::Find); # File::Find
    use utf8::all qw(Cwd);        # Cwd
    use utf8::all qw(:all);       # everything

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

readdir now returns UTF-8

=item *

L<glob|perlfunc/glob> and the C<< <> >> operator

=back

=head1 Import options

If you provide the C<File::Find> or C<Cwd> options to the
C<use utf8::all> line, those modules are loaded if they haven't
been already, but you will get UTF-8-ified versions instead of the
normal ones. This effect is lexical.

=over 4

=item L<File::Find>

C<find> and C<finddepth>

=item L<Cwd>

C<cwd>, C<fastcwd>, C<getcwd>, C<fastgetcwd>

C<abs_path>, C<realpath>, C<fast_abs_path>

=back

Use C<use utf8::all qw(:all)> to get all of these, plus whatever
we dream up in the future.

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

=cut

use Import::Into;
use parent qw(Encode charnames utf8 open warnings feature);
use Symbol qw(qualify_to_ref);

# Holds the pointers to the original version of redefined functions
state %_orig_functions;

my @KNOWN_OPTIONS = qw( File::Find Cwd ); # :all is a "tag"
sub import {
    my %options = map { $_ => 1 } @_[1 .. $#_]; # First entry in @_ is __PACKAGE__
    if (delete $options{':all'}) {
        $options{$_} = 1 for @KNOWN_OPTIONS;
    }
    # Only keep known opts
    for my $o (keys %options) { delete $options{$o} unless grep { /$o/ } @KNOWN_OPTIONS }

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
        *{$target . '::readdir'} = \&_utf8_readdir;
        $^H{'utf8::all::readdir'} = 1; # Track whether to encode/decode in the redefined function

        # Replace glob with utf8 aware version
        *{$target . '::glob'} = \&_utf8_glob;
        $^H{'utf8::all::glob'} = 1;

        # List of redefined non-core functions
        my @redefined;

        if ($options{'Cwd'}) {
            require Cwd;
            push @redefined, map "Cwd::$_" => qw(
                cwd fastcwd getcwd fastgetcwd
                abs_path realpath fast_abs_path
            );
        }

        if ($options{'File::Find'}) {
            require File::Find;
            push @redefined, map "File::Find::$_" => qw(find finddepth);
        }

        for my $f (@redefined) {
            $^H{"utf8::all::$f"} = 1;
            # If we already have the _orig_function, we have redefined the function
            # in an earlier load of the module, so we need not do it again
            unless ($_orig_functions{$f}) {
                $_orig_functions{$f} = \&{$f};
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
    if ($target eq 'main' && !$have_encoded_argv++) {
        $_ = Encode::decode('UTF-8' ,$_) for @ARGV;
    }

    $^H{'utf8::all'} = 1;

    return;
}

sub _utf8_simple_func {
    my $func = shift;
    my $hints = (caller 1)[10]; # Use caller level 1 because of the added anonymous sub around call
    if (not $hints->{"utf8::all::$func"}) {
        return $_orig_functions{$func}->(@_);
    }
    elsif (wantarray) {
        return map { Encode::decode('UTF-8' ,$_) }
            $_orig_functions{$func}->( map { Encode::encode('UTF-8', $_) } @_ );
    }
    else {
        return Encode::decode('UTF-8',
            $_orig_functions{$func}->(map { Encode::encode('UTF-8', $_) } @_)
        );
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
        return $_orig_functions{"File::Find::find"}->(\%find_options_hash, @_);
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
        return $_orig_functions{"File::Find::find"}->(\%find_options_hash, map { Encode::encode('UTF-8', $_) } @_);
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
