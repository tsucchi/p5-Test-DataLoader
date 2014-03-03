requires 'Class::Accessor::Lite';
requires 'DBI';
requires 'DBIx::TransactionManager';
requires 'SQL::Executor';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
};
