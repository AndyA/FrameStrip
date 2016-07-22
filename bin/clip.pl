#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use Getopt::Long;
use JSON::XS;
use Path::Class;
use String::ShellQuote;

use constant USAGE => <<EOT;
Usage: $0 [options] <infile> <outfile>

Options:

  -i, --in  <ms>    In point in milliseconds
  -o, --out <ms>    Out point in milliseconds

EOT

my %O = ( in => undef, out => undef );
GetOptions( 'i:i' => \$O{in}, 'o:i' => \$O{out} ) or die USAGE;

die USAGE unless @ARGV == 2;
my ( $infile, $outfile ) = @ARGV;

my $info = probe($infile);
my @iframes = grep { $_->{pict_type} eq "I" } @{ $info->{frames} };
print JSON::XS->new->pretty->canonical->encode( \@iframes );

sub probe {
  my $vid = shift;

  my @cmd = (
    'ffprobe', -show_frames => -select_streams => 'v',
    -print_format => 'json=c=1',
    $vid
  );

  my $work = Path::Class::tempdir( CLEANUP => 1 );
  my $out = file $work, 'frames.json';

  my $cmd = join ' ', shell_quote(@cmd), '>', shell_quote("$out");
  system $cmd;

  return JSON::XS->new->decode( scalar $out->slurp );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

