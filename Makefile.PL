use inc::Module::Install;
name                 'Test-DataLoader';
all_from             'lib/Test/DataLoader.pm';
readme_from          'lib/Test/DataLoader.pm';
readme_markdown_from 'lib/Test/DataLoader.pm';
readme_pod_from      'lib/Test/DataLoader.pm';
githubmeta;

requires 'DBI';
requires 'SQL::Executor';
requires 'Class::Accessor::Lite';
requires 'DBIx::TransactionManager';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
test_requires 'DBD::SQLite';
test_requires 'Test::Mock::Guard';

auto_set_repository;
auto_include;
WriteAll;
