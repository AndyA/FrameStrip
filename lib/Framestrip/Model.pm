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

}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
