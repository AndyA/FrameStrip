#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use Dancer ':script';
use Dancer::Plugin::Database;
use LWP::UserAgent;

use constant LIST => 'https://framestrip.hexten.net/asset/sprites/';

my $ua   = LWP::UserAgent->new;
my $resp = $ua->get(LIST);
die $resp->status_line if $resp->is_error;
my @ln = split /\n/, $resp->content;

my @ids = ();
for my $ln (@ln) {
  next unless $ln =~ m{folder\.gif};
  next unless $ln =~ m{href="(\d+)/"};
  push @ids, $1;
}

my $ph = join ', ', ('?') x @ids;
my $sql = join( ' ',
  "UPDATE `programmes`",
  "   SET `state` = ?",
  " WHERE `state` = ?",
  "   AND `redux_reference` IN ($ph)" );
database->do( $sql, {}, 'pending', 'unavailable', @ids );

# vim:ts=2:sw=2:sts=2:et:ft=perl

