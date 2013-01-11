#!perl
use strict;
use warnings;
use Test::DataLoader;
use DBI;
use SQL::Executor;
use Test::More;
use t::Util;

my $dbh = prepare_employee_db();

subtest 'find_data scalar context', sub {
    my $data = Test::DataLoader->new($dbh);
    $data->add('employee', 1, {
        id   => 123,
        name => 'aaa',
    }, ['id']);
    my $data_href = $data->find_data('employee', 1);
    is( $data_href->{id},   123);
    is( $data_href->{name}, 'aaa');
};

subtest 'find_data array context', sub {
    my $data = Test::DataLoader->new($dbh);
    $data->add('employee', 1, {
        id   => 123,
        name => 'aaa',
    }, ['id']);
    my ($data_href, $pk_names_aref) = $data->find_data('employee', 1);
    is( $data_href->{id},   123);
    is( $data_href->{name}, 'aaa');

    is_deeply($pk_names_aref, ['id']);
};

subtest 'keys specified by set_unique_keys', sub {
    my $data = Test::DataLoader->new($dbh);
    $data->add('employee', 1, {
        id   => 123,
        name => 'aaa',
    });
    $data->set_unique_keys('employee', ['id'], ['name']);#multiple unique keys

    my ($data_href, $pk_names_aref) = $data->find_data('employee', 1);
    is( $data_href->{id},   123);
    is( $data_href->{name}, 'aaa');

    is_deeply($pk_names_aref, ['id']);#returns only first key
};

subtest 'find_data replaced by option', sub {
    my $data = Test::DataLoader->new($dbh);
    $data->add('employee', 1, {
        id   => 123,
        name => 'aaa',
    }, ['id']);
    my $data_href = $data->find_data('employee', 1, { id => 234, name => 'bbb' });
    is( $data_href->{id},   234);
    is( $data_href->{name}, 'bbb');
};



$dbh->disconnect;

done_testing;

