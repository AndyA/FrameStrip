#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use JSON;
use Path::Class;
use XML::LibXML;

for my $file (@ARGV) {
  ( my $meta = $file ) =~ s/\.[^.]+$/.json/;
  next if -e $meta;
  say $file;
  my $info = analyse($file);
  my $tmp  = "$meta.tmp.json";
  print { file($tmp)->openw } JSON->new->pretty->canonical->encode($info);
  rename $tmp, $meta;
}

sub analyse {
  my $file = shift;
  my $info = mediainfo($file);

  my $vid = '//Mediainfo/File/track[@type="Video"]';

  return {
    bitrate  => mi_num( $info, "$vid/Bit_rate" ),
    width    => mi_num( $info, "$vid/Width" ),
    height   => mi_num( $info, "$vid/Height" ),
    duration => mi_num( $info, "$vid/Duration" ),
  };
}

sub mi_num {
  my ( $doc, $path ) = @_;
  for my $nd ( $doc->findnodes($path) ) {
    my $val = $nd->textContent;
    return $1 if $val =~ /^\s*(\d+)\s*$/;
  }
  return undef;
}

sub mediainfo {
  my $file = shift;
  my $xml = run_cmd( 'mediainfo', '--Full', '--Output=XML', $file );
  return XML::LibXML->load_xml( string => $xml );
}

sub run_cmd {
  open my $fh, '-|', @_;
  my $out = do { local $/; <$fh> };
  close $fh;
  return $out;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl
