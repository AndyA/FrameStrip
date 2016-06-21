#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use Dancer ':script';
use Dancer::Plugin::Database;
use JSON ();
use LWP::UserAgent;

use constant LIST  => 'https://framestrip.hexten.net/asset/sprites/';
use constant MEDIA => 'https://framestrip.hexten.net/asset/mpegts/';

my $ua = LWP::UserAgent->new;

database->do("START TRANSACTION");

{
  my @ids = sprites_available();
  my $ph  = join ', ', ('?') x @ids;
  my $sql = join( ' ',
    "UPDATE `programmes`",
    "   SET `state` = ?",
    " WHERE `state` = ?",
    "   AND `redux_reference` IN ($ph)" );

  database->do( $sql, {}, 'pending', 'unavailable', @ids );
}

{
  my $need = database->selectcol_arrayref(
    join( ' ',
      "SELECT `redux_reference`",
      "  FROM `programmes`",
      " WHERE `state` = ?",
      "   AND `duration` IS NULL" ),
    { Slice => {} },
    'pending'
  );

  for my $id (@$need) {
    my $url = MEDIA . "$id.json";
    #  say "Fetching metadata for $id ($url)";
    my $resp = $ua->get($url);
    next if $resp->code == 404;
    die $resp->status_line if $resp->is_error;
    my $meta = JSON->new->decode( $resp->content );
    database->do(
      "UPDATE `programmes` SET `duration` = ? WHERE `redux_reference` = ?",
      {}, $meta->{duration}, $id );
  }
}

{
  my $need = database->selectcol_arrayref(
    join( ' ',
      "SELECT `redux_reference`",
      "  FROM `programmes`",
      " WHERE `state` = ?",
      "   AND `zoom_levels` IS NULL" ),
    { Slice => {} },
    'pending'
  );

  for my $id (@$need) {
    my @zl = zoom_levels($id);
    #    say $id, " => ", join ', ', @zl;
    database->do(
      "UPDATE `programmes` SET `zoom_levels` = ? WHERE `redux_reference` = ?",
      {}, join( ',', @zl ), $id
    );
  }
}

database->do("COMMIT");

sub zoom_levels {
  my $id    = shift;
  my @dirs  = sub_dirs( LIST . $id . '/' );
  my @zooms = ();
  for my $dir (@dirs) {
    push @zooms, $1 if $dir =~ /^x(\d+)/;
  }
  return sort { $a <=> $b } @zooms;
}

sub sprites_available {
  return grep { /^\d+$/ } sub_dirs(LIST);
}

sub sub_dirs {
  my $url  = shift;
  my $resp = $ua->get($url);
  die $resp->status_line if $resp->is_error;
  my @ln = split /\n/, $resp->content;

  my @dirs = ();
  for my $ln (@ln) {
    next unless $ln =~ m{folder\.gif};
    next unless $ln =~ m{href="([^"]+)/"};
    push @dirs, $1;
  }
  return @dirs;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

