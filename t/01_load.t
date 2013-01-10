#!perl
use strict;
use warnings;
use Test::DataLoader;
use DBI;
use SQL::Executor;
use Test::More;
use t::Util;

subtest 'add/load', sub {
    my $dbh = prepare_employee_db();

    my $data = Test::DataLoader->new($dbh);
    $data->add_one('employee', 1, {
        id   => 123,
        name => 'aaa',
    }, ['id']);
    $data->load('employee', 1);

    my $ex = SQL::Executor->new($dbh);
    my $row = $ex->select_row('employee', { id => 123 });
    is( $row->{name}, 'aaa');

    $data->clear;
    $row = $ex->select_row('employee', { id => 123 });
    ok( !defined $row, '$row is removed'  );
    $dbh->disconnect;
};

subtest 'load twice but record is only 1(deleted before insert)', sub {
    my $dbh = prepare_employee_db();

    my $data = Test::DataLoader->new($dbh);
    $data->add_one('employee', 1, {
        id   => 123,
        name => 'aaa',
    }, ['id']);
    $data->load('employee', 1);
    $data->load('employee', 1);

    my $ex = SQL::Executor->new($dbh);
    my @rows = $ex->select_row('employee', { id => 123 });
    is( scalar(@rows), 1);
    is( $rows[0]->{name}, 'aaa');

    $data->clear;
    $dbh->disconnect;
};


subtest 'load with return value', sub {
    my $dbh = prepare_employee_db();

    my $data = Test::DataLoader->new($dbh);
    $data->add_one('employee', 1, {
        id   => 123,
        name => 'aaa',
    }, ['id']);
    my %loaded = $data->load('employee', 1);
    is( $loaded{id},   '123');
    is( $loaded{name}, 'aaa');

    $data->clear;
    $dbh->disconnect;
};

subtest 'load with auto_increment', sub {
    my $dbh = prepare_employee_db();

    my $data = Test::DataLoader->new($dbh);
    $data->add_one('employee', 1, {
        id   => undef,
        name => 'aaa',
    }, ['id']);
    my %loaded = $data->load('employee', 1);
    my $id = $dbh->sqlite_last_insert_rowid();
    is( $loaded{id},   $id);
    is( $loaded{name}, 'aaa');

    $data->clear;
    $dbh->disconnect;
};


subtest 'set_unique_keys', sub {
    my $dbh = prepare_employee_db();

    my $data = Test::DataLoader->new($dbh);
    $data->set_unique_keys('employee', ['id']);
    $data->add_one('employee', 1, {
        id   => 123,
        name => 'aaa',
    });
    $data->load('employee', 1);
    $data->clear;
    my $ex = SQL::Executor->new($dbh);
    my $row = $ex->select_row('employee', { id => 123 });
    ok( !defined $row, '$row is removed' );
    $dbh->disconnect;
};


done_testing;

