requires 'Class::Accessor::Lite';
requires 'DBI', '1.57';
requires 'DBIx::TransactionManager';
requires 'Otogiri', '0.06';
requires 'Otogiri::Plugin', '0.02';
requires 'Otogiri::Plugin::DeleteCascade';
requires 'parent';
requires 'perl', '5.008';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};

on test => sub {
    requires 'DBD::SQLite';
    requires 'Test::Mock::Guard';
};
