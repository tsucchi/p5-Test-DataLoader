package t::Util;
use parent qw(Exporter);
use strict;
use warnings;

our @EXPORT = qw(prepare);

sub prepare {
    my (%options) = @_;
    my $connect_info = ["dbi:SQLite:dbname=:memory:", '', '', { RaiseError => 1 }];
    my $data = Test::DataLoader->new(connect_info => $connect_info, %options);
    my $create_table = "
CREATE TABLE employee (
  id      INTEGER PRIMARY KEY,
  name    TEXT
);
";
    $data->db->do($create_table);
    return $data;
}


1;
