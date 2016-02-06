use strict;
use warnings;
use Test::DataLoader;
use Test::More;
use t::Util;

subtest 'add by external file and load', sub {
    my $data = prepare();

    $data->add_by_file('t/file/employee.pl');
    # $data->load_file('filename.pl') is equivarent to following
    # $data->set_keys('employee', ['id']);
    # $data->add('employee', 1, {
    #     id   => 123,
    #     name => 'aaa',
    # });

    $data->load('employee', 1);

    my $db = $data->db;
    my $row = $db->single('employee', { id => 123 });
    is( $row->{name}, 'aaa');

    $data->clear;
};

subtest 'add_by_file with using base_dir option', sub {
    my $data = prepare( base_dir => 't/file');

    $data->add_by_file('employee.pl');
    $data->load('employee', 1);

    my $db = $data->db;
    my $row = $db->single('employee', { id => 123 });
    is( $row->{name}, 'aaa');

    $data->clear;
};




done_testing;
