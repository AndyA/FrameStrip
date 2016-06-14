#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use Getopt::Long;
use Path::Class;

use constant SPRITE_WIDTH  => 16;
use constant SPRITE_HEIGHT => 16;

use constant USAGE => <<EOT;
Usage: $0 [options] <video> ...

Options:

  -o, --output <dir>    Output to dir. Default "./output"
  -s, --size   <W>x<H>  Tile size. Default "128x72"

EOT

my %O = ( output => 'output', size => '128x72' );

GetOptions(
  'o|output:s' => \$O{output},
  's|size:s'   => \$O{size}
) or die USAGE;

for my $vid (@ARGV) {
  process($vid);
}

sub process {
  my $vid = file shift;

  ( my $name = $vid->basename ) =~ s/\.[^.]+$//;

  my $frames_dir   = dir $O{output}, 'frames',       $name;
  my $sprites_dir  = dir $O{output}, 'sprites',      $name;
  my $sprites_work = dir $O{output}, 'sprites.work', $name;

  if ( -e $sprites_dir ) {
    say "$sprites_dir already exists";
    return;
  }

  $sprites_work->rmtree if -d $sprites_work;

  extract_frames( $vid, $frames_dir );
  #  merge_frames($frames_dir);
  make_sprites( $frames_dir, $sprites_work );
  $sprites_dir->parent->mkpath;
  rename $sprites_work, $sprites_dir;
}

sub extract_frames {
  my ( $vid, $frames_dir ) = @_;

  $frames_dir->mkpath;
  my $frame = file $frames_dir, 'f%08d.png';

  my @cmd = (
    'ffmpeg',
    '-nostdin',
    -i      => $vid,
    -vf     => 'pad=max(iw\,ih*(16/9)):ow/(16/9):(ow-iw)/2:(oh-ih)/2',
    -aspect => '16:9',
    -s      => $O{size},
    -y      => $frame
  );
  say join ' ', @cmd;
  system @cmd;
  die $? if $?;
}

sub merge_frames {
  my ($frames_dir) = @_;

  my $prev = 1;
  my $next = $prev * 2;
  while () {
    my $in_dir  = dir $frames_dir, 'x' . $prev;
    my $out_dir = dir $frames_dir, 'x' . $next;
    $out_dir->mkpath;
    my @in = sort grep { "$_" =~ /\.png$/ } $in_dir->children;
    say "$in_dir, $out_dir";
    say join( " ", @in );
    my $idx = 0;
    while (@in) {
      my $out = file $out_dir, sprintf "f%08d.png", $idx++;
      if ( @in > 2 ) {
        my @img = splice @in, 0, 2;
        my @cmd = (
          'convert',
          @img,
          '-evaluate-sequence' => 'mean',
          $out
        );
        say join ' ', @cmd;
        system @cmd;
        die $? if $?;
      }
      else {
        link $in[0], $out;
      }
    }

    last if @in < SPRITE_WIDTH * SPRITE_HEIGHT;
    $prev = $next;
    $next *= 2;
  }
}

sub make_sprites {
  my ( $frames_dir, $sprites_dir ) = @_;

  my @frames = sort $frames_dir->children;
  my $chunk  = SPRITE_WIDTH * SPRITE_HEIGHT;

  for ( my $step = 1; @frames / $chunk / $step > 1; $step *= 2 ) {
    my $step_dir = dir $sprites_dir, 'x' . $step;
    say $step_dir;
    $step_dir->mkpath;
    my @fr = get_frames( $step, @frames );
    my $next = 0;
    while (@fr) {
      my $sprite = file $step_dir, sprintf "s%04d.jpg", $next++;
      my @src = splice @fr, 0, $chunk;
      push @src, ('xc:black') x ( $chunk - @src ) if @src < $chunk;
      my @cmd = (
        'montage',
        -size => $O{size},
        @src,
        -geometry => '+0+0',
        -tile     => join( 'x', SPRITE_WIDTH, SPRITE_HEIGHT ),
        $sprite
      );
      say join ' ', @cmd;
      system @cmd;
      die $? if $?;
    }
  }
}

sub get_frames {
  my ( $step, @frames ) = @_;
  return @frames if $step == 1;
  my @out = ();
  for ( my $i = 0; $i < @frames; $i += $step ) {
    push @out, $frames[$i];
  }
  return @out;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

