use strict;
use warnings;
use Test::More tests => 4;
use Capture::Tiny qw(capture_merged);

my $fatal_code_str = q{ use utf8::all; print "\x{FFFE}" };
my $fatal_out = capture_merged sub { system( $^X, '-Ilib', '-e', $fatal_code_str ) };
isnt $?, 0, 'Fatal command failed';
like $fatal_out => qr/Unicode/, 'Fatal command gave "Unicode non-character" fatal error';
like $fatal_out => qr/FFFE/i, 'Fatal command identified \x{FFFE} as the culprit';


my $ok_code_str = q{ use utf8::all; no warnings FATAL => 'utf8'; print "\x{FFFE}" };
my $ok_out = capture_merged sub { system( $^X, '-Ilib', '-e', $ok_code_str ) };
is $?, 0, 'Non-fatal command succeeded';
