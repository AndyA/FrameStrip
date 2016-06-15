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

my @ids = sprites_available(LIST);

database->do("START TRANSACTION");

my $ph = join ', ', ('?') x @ids;
my $sql = join( ' ',
  "UPDATE `programmes`",
  "   SET `state` = ?",
  " WHERE `state` = ?",
  "   AND `redux_reference` IN ($ph)" );

database->do( $sql, {}, 'pending', 'unavailable', @ids );

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

database->do("COMMIT");

sub sprites_available {
  my $list = shift;
  my $resp = $ua->get($list);
  die $resp->status_line if $resp->is_error;
  my @ln = split /\n/, $resp->content;

  my @ids = ();
  for my $ln (@ln) {
    next unless $ln =~ m{folder\.gif};
    next unless $ln =~ m{href="(\d+)/"};
    push @ids, $1;
  }
  return @ids;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

