#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use utf8;
use warnings;

use Dancer ':script';
use Dancer::Plugin::Database;
use JSON ();
use Path::Class;
use Text::CSV_XS;

binmode( STDOUT, ":utf8" );

use constant SRC => dir('ref/list.csv');

my $data = load_csv(SRC);

database->do("START TRANSACTION");
database->do("TRUNCATE `$_`") for 'programmes';

load_data( database, $data );

database->do("COMMIT");

sub load_data {
  my ( $dbh, $data ) = @_;

  my @cols  = ();
  my @queue = ();

  my $flush = sub {
    return unless @queue;
    my $val = '(' . join( ', ', map '?', @cols ) . ')';
    my $sql = join ' ', 'INSERT INTO `programmes` (',
     join( ', ', map "`$_`", @cols ), ') VALUES',
     join( ', ', map $val, @queue );
    my @bind = map { @$_ } splice @queue;
    $dbh->do( $sql, {}, @bind );
  };

  for my $row (@$data) {
    my $rec = {};
    while ( my ( $col, $val ) = each %$row ) {
      ( my $ncol = lc $col ) =~ s/\s+/_/g;
      $rec->{$ncol} = $val if length $ncol;
    }
    $rec->{date} = fix_date( $rec->{date} );
    $rec->{redux_reference} =~ s/^'//;
    $rec->{duration} = undef unless length $rec->{duration};
    #    say JSON->new->pretty->canonical->encode($rec);
    printf "%-40s %s\n", $rec->{redux_reference}, $rec->{programme_name};
    @cols = sort keys %$rec unless @cols;
    push @queue, [@{$rec}{@cols}];
    $flush->() if @queue >= 500;
  }

  $flush->();
}

sub fix_date {
  my $dt = shift;
  my ( $m, $d, $y ) = split /\//, $dt;
  return unless defined $y;
  if ( length $y < 4 ) {
    $y += 1900;
    $y += 100 if $y < 1930;
  }
  return join '-', $y, map { sprintf '%02d', $_ } $m, $d;
}

sub format_uuid {
  my ($uuid) = @_;
  return join '-', $1, $2, $3, $4, $5
   if $uuid =~ /^ ([0-9a-f]{8}) -?
                  ([0-9a-f]{4}) -?
                  ([0-9a-f]{4}) -?
                  ([0-9a-f]{4}) -?
                  ([0-9a-f]{12}) $/xi;
  die "Bad UUID";
}

sub tidy {
  my $s = shift;
  s/^\s+//, s/\s+$//, s/\s+/ /g for $s;
  return $s;
}

sub load_csv {
  my $file = shift;

  my $fh = file($file)->openr;
  $fh->binmode('utf8');
  my $csv = Text::CSV_XS->new(
    { binary       => 1,
      auto_diag    => 1,
      diag_verbose => 1,
    }
  );
  my $data = [];

  my @hdr = ();
  while ( my $row = $csv->getline($fh) ) {
    my @fld = map { tidy($_) } @$row;
    next unless length join '', @fld[1 .. $#fld];    # Ignore blank lines

    unless (@hdr) {
      @hdr = @fld;
      next;
    }

    my $rec = {};
    @{$rec}{@hdr} = @fld;
    push @$data, $rec;
  }

  return $data;
}

sub show_sql {
  my ( $sql, undef, @bind ) = @_;
  my $next = sub {
    my $val = shift @bind;
    return 'NULL' unless defined $val;
    return $val if $val =~ /^\d+(?:\.\d+)?$/;
    $val =~ s/\\/\\\\/g;
    $val =~ s/\n/\\n/g;
    $val =~ s/\t/\\t/g;
    $val =~ s/'/''/g;
    return "'$val'";
  };
  $sql =~ s/\?/$next->()/eg;
  $sql .= join ' ', ' #', scalar(@bind), 'values unused' if @bind;
  return $sql;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl
