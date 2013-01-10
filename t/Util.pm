package t::Util;
use parent qw(Exporter);
use strict;
use warnings;

our @EXPORT = qw(prepare_employee_db);

sub prepare_employee_db {
    my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:",'','');
    $dbh->do("
CREATE TABLE employee (
  id      INTEGER PRIMARY KEY,
  name    TEXT
);
") or die $dbh->errstr;
     return $dbh;
}


1;
