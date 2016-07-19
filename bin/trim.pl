#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use utf8;
use warnings;

use Dancer ':script';
use Dancer::Plugin::Database;
use Getopt::Long;
use JSON::XS;
use Path::Class;

use constant USAGE => <<EOT;
Syntax: $0 [options] <vid>...

Options:

  -o, --outdir  <dir>  Output directory
  -e, --ext     <ext>  Output extension

EOT

my %O = (
  outdir => 'out',
  ext    => 'ts',
);

GetOptions(
  'o|outdir:s' => \$O{outdir},
  'e|ext:s'    => \$O{ext},
) or die USAGE;

my $logf = file $O{outdir}, "log.txt";
$logf->parent->mkpath;
my $lh = $logf->openw;

for my $vid (@ARGV) {
  my $vf = file $vid;

  ( my $name = $vf->basename ) =~ s/(\d+)\..*$/$1/;

  my $info = database->selectrow_hashref(
    join( " ",
      "SELECT *",
      "  FROM `programmes` AS `p`",
      "  LEFT JOIN `programme_edits` AS `e`",
      "    ON `e`.`redux_reference` = `p`.`redux_reference`",
      " WHERE `p`.`redux_reference` = ?" ),
    {},
    $name
  );

  unless ( $info && defined $info->{in} && defined $info->{out} ) {
    warn "No edit info for $vf";
    next;
  }

  my $out = file $O{outdir}, "$name.$O{ext}";
  my $tmp = file $O{outdir}, "$name.tmp.$O{ext}";

  my $start    = $info->{in} / 1000;
  my $duration = ( $info->{out} - $info->{in} ) / 1000;
  say $lh join "\t", $out, $start, $duration;

  my @cmd = (
    'ffmpeg',
    -fflags => '+genpts',
    -ss     => $start,
    -i      => $vf,
    -c      => 'copy',
    -t      => $duration,
    -y      => $tmp
  );

  say join ' ', @cmd;
  $out->parent->mkpath;
  system @cmd;
  rename $tmp, $out;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

