package Framestrip::Model;

use Moose;

=head1 NAME

Framestrip::Model - Database abstraction

=cut

has dbh => ( is => 'ro', isa => 'DBI::db' );

sub asset {
  my ( $self, $id ) = @_;
  my $data = $self->dbh->selectrow_hashref(
    join( ' ',
      "SELECT p.*, e.in, e.out, e.when",
      "  FROM programmes AS p",
      "  LEFT JOIN programme_edits AS e",
      "    ON e.redux_reference = p.redux_reference",
      " WHERE p.redux_reference = ?" ),
    {},
    $id
  );

  return $data;
}

sub list {
  my ( $self, $start, $size, $filter, $order ) = @_;

  $start  //= 0;
  $size   //= 30;
  $filter //= {};
  $order  //= '+programme_name';

  my @filter = ();
  my @bind   = ();

  while ( my ( $fld, $val ) = each %$filter ) {
    die unless $fld =~ /^\w+$/;
    push @filter, "p.`$fld` = ?";
    push @bind,   $val;
  }

  my @order = ();
  for my $term ( split /,/, $order ) {
    my ( $dir, $fld ) = $term =~ m{(.)(.+)};
    die unless $fld =~ /^\w+$/;
    push @order, join ' ', "`$fld`",
     $dir eq '+' ? "ASC" : $dir eq '-' ? "DESC" : die;
  }

  my ($count) = $self->dbh->selectrow_array(
    join( ' ',
      "SELECT COUNT(*) FROM programmes",
      ( @filter ? ( "WHERE", join( " AND ", @filter ) ) : () ),
    ),
    {},
    @bind
  );

  my $list = $self->dbh->selectall_arrayref(
    join( ' ',
      "SELECT p.*, e.in, e.out, e.when",
      "  FROM programmes AS p",
      "  LEFT JOIN programme_edits AS e",
      "    ON e.redux_reference = p.redux_reference",
      ( @filter ? ( "WHERE", join( " AND ", @filter ) ) : () ),
      ( @order ? ( "ORDER BY", join ", ", @order ) : () ),
      " LIMIT ?, ?" ),
    { Slice => {} },
    @bind, $start, $size
  );

  return { list => $list, count => $count };
}

sub parse_timecode {
  my ( $self, $tc ) = @_;
  my @p = split /:/, $tc;
  my @lim = ( 24, 60, 60, 25 );
  die "Bad timecode $tc" unless @p == @lim;
  my $time = 0;
  while (@lim) {
    my $lim = shift @lim;
    my $p   = shift @p;
    die "Bad timecode $tc" unless $p =~ /^\d+$/ && $p <= $lim;
    $time = ( $time * $lim ) + $p;
  }
  return $time;
}

sub update {
  my ( $self, $id, $in, $out ) = @_;
  my $in_time  = $self->parse_timecode($in) * 1000 / 25;
  my $out_time = $self->parse_timecode($out) * 1000 / 25;
  $self->dbh->do(
    join( " ",
      "REPLACE INTO `programme_edits` (`redux_reference`, `in`, `out`, `when`) VALUES (?, ?, ?, NOW())"
    ),
    {},
    $id, $in_time,
    $out_time
  );
  $self->dbh->do(
    "UPDATE `programmes` SET state = ? WHERE `redux_reference` = ?",
    {}, 'done', $id );
  $self->dbh->do(
    "DELETE FROM `programme_locks` WHERE `redux_reference` = ?",
    {}, $id );
}

sub prune_locks {
  my $self = shift;
  $self->dbh->do(
    "DELETE FROM `programme_locks` WHERE `when` < DATE_SUB(NOW(), INTERVAL 1 MINUTE)"
  );
}

sub lock {
  my ( $self, $id, $node ) = @_;
  $self->dbh->do(
    "REPLACE INTO `programme_locks` (`redux_reference`, `node`, `when`) VALUES (?, ?, NOW())",
    {}, $id, $node
  );
}

sub random {
  my $self = shift;
  $self->prune_locks;
  my ( $id, undef ) = $self->dbh->selectrow_array(
    join( ' ',
      "SELECT p.redux_reference, pl.when",
      "  FROM programmes AS p",
      "  LEFT JOIN programme_locks AS pl",
      "    ON pl.redux_reference = p.redux_reference",
      " WHERE p.state = ?",
      "HAVING pl.when IS NULL",
      " ORDER BY RAND()",
      " LIMIT 1" ),
    {},
    'pending'
  );
  return $id;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
