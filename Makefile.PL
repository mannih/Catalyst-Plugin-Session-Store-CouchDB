#!/usr/bin/env perl
use inc::Module::Install 1.01;

name 'Catalyst-Plugin-Session-Store-CouchDB';

all_from 'lib/Catalyst/Plugin/Session/Store/CouchDB.pm';

requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Exception';
requires 'Moose';
requires 'namespace::autoclean';
requires 'TryCatch';
requires 'LWP::UserAgent' => '6.04';
requires 'Encode';
requires 'HTTP::Headers';
requires 'HTTP::Request';
requires 'JSON';
requires 'Module::Runtime';
requires 'Storable';

test_requires 'Test::More' => '0.88';
test_requires 'Test::WWW::Mechanize::Catalyst';
test_requires 'Test::Exception';
test_requires 'MooseX::Storage';
test_requires 'IO::Socket::INET';

resources(
    'license',    => 'http://dev.perl.org/licenses/',
    'repository', => 'git@github.com:mannih/Catalyst-Plugin-Session-Store-CouchDB.git',
);

auto_install;
WriteAll;
