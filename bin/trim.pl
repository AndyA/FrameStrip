#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use utf8;
use warnings;

use Dancer ':script';
use Dancer::Plugin::Database;
use File::Find;
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

for my $vid (@ARGV) {
  process($vid);
}

sub process {
  for my $obj (@_) {
    if ( -d $obj ) {
      find {
        wanted => sub {
          return unless /\.(?:mpeg)ts$/i;
          trim($_);
        },
        no_chdir => 1
      }, $obj;
    }
    else {
      trim($obj);
    }
  }
}

sub get_info {
  my $name = shift;

  return database->selectrow_hashref(
    join( " ",
      "SELECT *",
      "  FROM `programmes` AS `p`",
      "  LEFT JOIN `programme_edits` AS `e`",
      "    ON `e`.`redux_reference` = `p`.`redux_reference`",
      " WHERE `p`.`redux_reference` = ?" ),
    {},
    $name
  );
}

sub trim {
  my $vf = file $_[0];

  ( my $name = $vf->basename ) =~ s/(\d+)\..*$/$1/;
  my $out = file $O{outdir}, "$name.$O{ext}";

  if ( -e $out && -M $out < -M $vf ) {
    warn "$out exists and is newer\n";
    return;
  }

  my $info = get_info($name);

  unless ( $info && defined $info->{in} && defined $info->{out} ) {
    warn "No edit info for $vf\n";
    return;
  }

  my $tmp = file $O{outdir}, "$name.tmp.$O{ext}";

  my $start    = $info->{in} / 1000;
  my $duration = ( $info->{out} - $info->{in} ) / 1000;

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

  if ($?) {
    warn "Failed to process $vf\n";
    return;
  }

  rename $tmp, $out;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

