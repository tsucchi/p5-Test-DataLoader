package Test::DataLoader;
use strict;
use warnings;
use Carp qw();
use DBIx::TransactionManager;
use DBIx::Inspector;
use Otogiri;
use Otogiri::Plugin;
use File::Basename qw();

use Class::Accessor::Lite (
    ro => ['teardown_style', 'txn_manager', 'db', 'inspector'],
    rw => ['loaded', 'key_names', 'cleared'],
);

our $VERSION = '0.01';

our $rollback_teardown   = 1;
our $delete_teardown     = 0;
our $do_nothing_teardown = -1;

Otogiri->load_plugin('DeleteCascade');

sub new {
    my ($class, %args) = @_;
    my $connect_info = $args{connect_info};
    my $teardown_style = defined $args{teardown} ? $args{teardown} : $rollback_teardown;
    my $db  = Otogiri->new( connect_info => $connect_info );
    my $txn = DBIx::TransactionManager->new($db->dbh);
    my $inspector = DBIx::Inspector->new( dbh => $db->dbh );
    my $self = {
        txn_manager    => $txn,
        inspector      => $inspector,
        db             => $db,
        data           => {},
        loaded         => [],
        key_names      => {},
        teardown_style => $teardown_style,
        cleared        => 1,
    };
    bless $self, $class;
}

sub add {
    my ($self, $table_name, $data_id, $data_href, $pk_aref) = @_;
    $self->{data}->{$table_name}->{$data_id} = [$data_href, $pk_aref];
}

sub load {
    my ($self, $table_name, $data_id, $option_href) = @_;

    my $txn = $self->txn_manager;
    if( $self->teardown_style eq $rollback_teardown && !$txn->in_transaction ) {
        $txn->txn_begin();
    }

    my ($data_href, $pk_names_aref) = $self->find_data($table_name, $data_id, $option_href);
    $pk_names_aref = $self->detect_primary_key($table_name) if ( !defined $pk_names_aref );
    my $pk_href = $self->pk_href($data_href, $pk_names_aref);
    Carp::croak "primary key is not defined" if ( !defined $pk_href || !%{ $pk_href } );

    $self->db->delete_cascade($table_name, $pk_href);
    $self->db->fast_insert($table_name, $data_href);
    for my $pk_name ( @{ $pk_names_aref || [] } ) {
        if ( !defined $pk_href->{$pk_name} ) {
            my $id = $self->db->last_insert_id();
            $option_href->{$pk_name} = $id;
            $pk_href->{$pk_name}     = $id;
        }
    }
    if ( $self->teardown_style eq $delete_teardown ) {
        $self->_add_loaded($table_name, $data_id, $option_href);
    }
    $self->cleared(0);

    return if ( !wantarray() );

    my $row = $self->db->single($table_name, $pk_href);
    return %{ $row || {} };
}

sub add_by_file {
    my ($self, $file_name) = @_;
    Carp::croak("$file_name is not exist")    if ( !-e $file_name );
    Carp::croak("$file_name is not .pl file") if ( $file_name !~ qr/\.pl$/ );

    my $value = do($file_name);
    Carp::croak($@) if ( $@ );

    if( !defined $value->{table_name} ) {
        ($value->{table_name} = File::Basename::basename($file_name)) =~ s/\.pl$//;
    }
    $self->_add_data($value);
}

sub _add_data {
    my ($self, $value) = @_;

    my $table_name = $value->{table_name};
    my $key        = $value->{unique_keys};
    Carp::croak("can't determin primary key") if ( !defined $key || ref $key ne 'ARRAY' );

    $key = [$key] if ( ref $key->[0] ne 'ARRAY' );
    $self->set_unique_keys($table_name, @{ $key });

    my $data = $value->{data};
    Carp::croak("data not found") if ( !defined $data );

    for my $datum_key ( sort keys %{ $data } ) {
        $self->add($table_name, $datum_key, $data->{$datum_key});
    }
}

sub find_data {
    my ($self, $table_name, $data_id, $option_href) = @_;
    my ($data_href, $pk_names_aref) = @{ $self->{data}->{$table_name}->{$data_id} };
    $pk_names_aref = $self->key_names->{$table_name}->[0] if ( !defined $pk_names_aref );
    for my $key ( keys %{ $option_href || {} } ) {
        $data_href->{$key} = $option_href->{$key};
    }
    return ($data_href, $pk_names_aref) if ( wantarray() );
    return $data_href;
}


sub pk_href {
    my ($self, $data_href, $pk_names_aref) = @_;
    my %pk = map{ $_ => $data_href->{$_} } @{ $pk_names_aref || [] };
    return \%pk;
}

sub _add_loaded {
    my ($self, $table_name, $data_id, $option_href) = @_;
    my ($data_href, $pk_aref) = $self->find_data($table_name, $data_id, $option_href);

    if( defined $pk_aref ) {
        push @{ $self->loaded }, [$table_name, $data_href, $pk_aref];
    }
    elsif( defined $self->key_names->{$table_name} ) {
        for my $pk_aref ( @{ $self->key_names->{$table_name} } ) {
            push @{ $self->loaded }, [$table_name, $data_href, $pk_aref];
        }
    }
    else {
        Carp::croak("primary key is not defined in $table_name : $data_id");
    }
}

sub clear {
    my ($self) = @_;

    if ( !$self->cleared && !$self->db->dbh->ping ) { # may be disconnected
        Carp::croak "already disconnected but data is not cleared\n";
    }

    if( $self->teardown_style eq $rollback_teardown ) {
        $self->_do_rollback_teardown;
    }
    elsif( $self->teardown_style eq $delete_teardown ) {
        $self->_do_delete_teardown;
    }
    $self->loaded([]);
    $self->cleared(1);
}

sub _do_rollback_teardown {
    my ($self) = @_;
    my $tm = $self->txn_manager;
    if( $tm->in_transaction ) {
        $tm->txn_rollback;
    }
}

sub _do_delete_teardown {
    my($self) = @_;
    for my $loaded ( reverse @{ $self->loaded } ) { #reverse for FK
        $self->_delete_each($loaded);
    }
}

sub _delete_each {
    my ($self, $datum) = @_;
    my ($table_name, $data_href, $pk_aref) = @{ $datum };

    return if ( !defined $pk_aref || !@{ $pk_aref } );

    my %pk = map{ $_ => $data_href->{$_} } @{ $pk_aref };
    Carp::croak "Primary Key is not defined" if ( !%pk );
    $self->db->delete_cascade($table_name, \%pk);
}

sub set_unique_keys {
    my ($self, $table_name, @keys_arefs) = @_;
    $self->key_names->{$table_name} = \@keys_arefs;
}

sub detect_primary_key {
    my ($self, $table_name) = @_;
    my $table = $self->inspector->table($table_name);

    return if ( !defined $table );

    my @pk = map { $_->column_name } $table->primary_key();
    return \@pk;
}

sub DESTROY {
    my ($self) = @_;
    Carp::carp("clear was not called") if ( !$self->cleared );
    $self->clear;
}


1;
__END__

=head1 NAME

Test::DataLoader - Load testdata into database

=head1 SYNOPSIS

  use Test::DataLoader;
  use DBI;
  my $dbh = DBI->connect(...);
  my $data = Test::DataLoader->new($dbh);
  #
  # define/add testdata
  $data->add('some_table', 1, {# data_href: column => value
      id   => 1, 
      name => 'aaa',
  }, ['id']); # primary keys
  $data->add('foo', 2, {
      id   => 2,
      name => 'bbb',
  }, ['id']);
  #
  # load data into database
  $data->load('foo', 1); 
  #
  # load data into database and got loaded data
  my $loaded = $data->load('foo', 2); # $loaded => { id => 2, name => 'bbb' }
  # ... tests using database
  $data->clear;# when finished

  #
  # if table has auto_increment
  #
  $data->add('foo', 1, {
               name => 'aaa',
  }, ['id']); #id is auto_increment column
  my $keys = $data->load('foo', 1);#load data and get auto_increment
  is( $keys->{id}, 2); # get key value(generated by auto_increment)
  # ... tests using database
  $data->clear;# when finished

  #
  # read from external file
  #
  # employee.pl
  +{
      # table_name can be omitted. In this case, filename(except .pl) is used for table_name.
      # table_name => 'employee',
      data => {
          1 => {
              id   => 123,
              name => 'aaa',
          },
      },
      unique_keys => ['id'],
  }
  # this file is same as 
  # $data->add('employee', 1, { id => 123, name => 'aaa' }, ['id']);
  #
  # in your testcode
  my $data = Test::DataLoader->new($dbh);
  $data->add_by_file('path/to/employee.pl');
  $data->load('employee', 1);
  # ... tests using database
  $data->clear;# when finished

=head1 DESCRIPTION

Test::DataLoader is testdata loader to database.

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi {at} cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
