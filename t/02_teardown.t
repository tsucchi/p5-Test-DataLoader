use strict;
use warnings;
use Test::DataLoader;
use Test::More;
use Test::Mock::Guard qw(mock_guard);
use Carp qw();
use t::Util;


subtest 'rollback_teardown (explicitly specified)', sub {
    my ($guard, $count_href) = init_mock_and_counter();
    my $data = prepare_loader($Test::DataLoader::rollback_teardown);

    no_transaction_used_ok($data, $count_href);# no transaction issued before load

    $data->load('employee', 1);

    transaction_rollbacked_ok($data, $count_href);
};

subtest 'rollback_teardown (default)', sub {
    my ($guard, $count_href) = init_mock_and_counter();
    my $data = prepare_loader();
    $data->load('employee', 1);

    transaction_rollbacked_ok($data, $count_href);
};

subtest 'delete_teardown', sub {
    my ($guard, $count_href) = init_mock_and_counter();
    my $data = prepare_loader($Test::DataLoader::delete_teardown);
    $data->load('employee', 1);

    no_transaction_used_ok($data, $count_href);
};

subtest 'do_nothing_teardown', sub {
    my ($guard, $count_href) = init_mock_and_counter();
    my $guard_for_data_loader = mock_guard('Test::DataLoader', +{
        _do_delete_teardown => sub { Carp::croak "unexpected _do_delete_teardown called()" },
    });
    my $data = prepare_loader($Test::DataLoader::do_nothing_teardown);
    $data->load('employee', 1);

    no_transaction_used_ok($data, $count_href);
};


done_testing;

sub prepare_loader {
    my ($teardown_style) = @_;
    my $data = prepare(teardown => $teardown_style);

    $data->add('employee', 1, {
        id   => 123,
        name => 'aaa',
    }, ['id']);
    return $data;
}

sub transaction_rollbacked_ok {
    my ($data, $count_href) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is( $count_href->{begin_work}, 1, 'begin_work');# transaction started
    $data->clear;
    is( $count_href->{rollback}, 1, 'rollback');# rollback issued
    is( $count_href->{commit},   0, 'commit');# no commit
}

sub no_transaction_used_ok {
    my ($data, $count_href) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is( $count_href->{begin_work}, 0, 'begin_work is not issued');
    $data->clear;
    is( $count_href->{rollback}, 0, 'rollback is not issued');
    is( $count_href->{commit},   0, 'commit is not issued');
}

sub init_mock_and_counter {
    my %count = (
        begin_work => 0,
        commit     => 0,
        rollback   => 0,
    );
    my $guard = mock_guard('DBI::db', +{
        begin_work => sub { $count{begin_work}++; return 1 },#return 1 for DBIx::TransactionManager
        commit     => sub { $count{commit}++     },
        rollback   => sub { $count{rollback}++;  },
    });
    return ($guard, \%count);
}

