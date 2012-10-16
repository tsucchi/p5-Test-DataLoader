use inc::Module::Install;
name 'Test-DataLoader';
all_from 'lib/Test/DataLoader.pm';
readme_from 'lib/Test/DataLoader.pm';
readme_markdown_from 'lib/Test/DataLoader.pm';
readme_pod_from 'lib/Test/DataLoader.pm';
githubmeta;

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
