use strict;
use warnings;
use Test::DataLoader;
use Test::More;
use t::Util;

subtest 'add/load', sub {
    my $data = prepare();
    $data->add('employee', 1, {
        id   => 123,
        name => 'aaa',
    }, ['id']);
    $data->load('employee', 1);

    my $db = $data->db;
    my $row = $db->single('employee', { id => 123 });
    is( $row->{name}, 'aaa');

    $data->clear;
    $row = $db->single('employee', { id => 123 });
    ok( !defined $row, '$row is removed'  );
};

subtest 'load twice but record is only 1(deleted before insert)', sub {
    my $data = prepare();

    $data->add('employee', 1, {
        id   => 123,
        name => 'aaa',
    }, ['id']);
    $data->load('employee', 1);
    $data->load('employee', 1);

    my $db = $data->db;
    my @rows = $db->select('employee', { id => 123 });
    is( scalar(@rows), 1);
    is( $rows[0]->{name}, 'aaa');

    $data->clear;
};


subtest 'load with return value', sub {
    my $data = prepare();

    $data->add('employee', 1, {
        id   => 123,
        name => 'aaa',
    }, ['id']);
    my %loaded = $data->load('employee', 1);
    is( $loaded{id},   '123');
    is( $loaded{name}, 'aaa');

    $data->clear;
};

subtest 'load with auto_increment', sub {
    my $data = prepare();

    $data->add('employee', 1, {
        id   => undef,
        name => 'aaa',
    }, ['id']);
    my %loaded = $data->load('employee', 1);
    my $db = $data->db;
    my $id = $db->last_insert_id();
    is( $loaded{id},   $id);
    is( $loaded{name}, 'aaa');

    $data->clear;
};


subtest 'set_unique_keys', sub {
    my $data = prepare();

    $data->set_unique_keys('employee', ['id']);
    $data->add('employee', 1, {
        id   => 123,
        name => 'aaa',
    });
    $data->load('employee', 1);
    $data->clear;
    my $db = $data->db;
    my $row = $db->single('employee', { id => 123 });
    ok( !defined $row, '$row is removed' );
};


done_testing;

