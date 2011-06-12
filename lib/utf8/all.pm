package utf8::all;
use strict;
use warnings;
use 5.010; # state
# ABSTRACT: turn on Unicode - all of it
# VERSION

=head1 SYNOPSIS

    use utf8::all; # Turn on UTF-8. All of it.

    open my $in, '<', 'contains-utf8';  # UTF-8 already turned on here
    print length 'føø bār';             # 7 UTF-8 characters
    my $utf8_arg = shift @ARGV;         # @ARGV is UTF-8 too!

=head1 DESCRIPTION

L<utf8> allows you to write your Perl encoded in UTF-8. That means UTF-8
strings, variable names, and regular expressions. C<utf8::all> goes further, and
makes C<@ARGV> encoded in UTF-8, and filehandles are opened with UTF-8 encoding
turned on by default (including STDIN, STDOUT, STDERR). If you I<don't> want
UTF-8 for a particular filehandle, you'll have to set C<binmode $filehandle>.

The pragma is lexically-scoped, so you can do the following if you had some
reason to:

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

use Encode ();
use parent 'utf8';
use parent 'open';

sub import {
    my $class = shift;

    $^H{'utf8::all'} = 1;
    
    # utf8 source code
    utf8::import($class);

    # utf8 by default on filehandles
    open::import($class, ':encoding(UTF-8)');
    open::import($class, ':std');

    # utf8 in @ARGV
    state $have_encoded_argv = 0;
    _encode_argv() unless $have_encoded_argv++;
    return;
}

sub _encode_argv {
    $_ = Encode::decode('UTF-8', $_) for @ARGV;
    return;
}

=for Pod::Coverage
utf8_open
unimport
=cut

1;
