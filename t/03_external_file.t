#!perl
use strict;
use warnings;
use Test::DataLoader;
use DBI;
use SQL::Executor;
use Test::More;
use t::Util;

subtest 'add by external file and load', sub {
    my $dbh = prepare_employee_db();

    my $data = Test::DataLoader->new($dbh);
    $data->add_by_file('t/file/employee.pl');
    # $data->load_file('filename.pl') is equivarent to following
    # $data->set_keys('employee', ['id']);
    # $data->add('employee', 1, {
    #     id   => 123,
    #     name => 'aaa',
    # });

    $data->load('employee', 1);

    my $ex = SQL::Executor->new($dbh);
    my $row = $ex->select_row('employee', { id => 123 });
    is( $row->{name}, 'aaa');

    $data->clear;
    $dbh->disconnect;
};



done_testing;
