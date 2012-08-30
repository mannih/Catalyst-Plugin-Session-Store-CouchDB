package SessionTestApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    Session
    Session::Store::CouchDB
    Session::State::Cookie
/;

extends 'Catalyst';

our $VERSION = '0.01';


__PACKAGE__->config(
    name => 'SessionTestApp',
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1,
);


__PACKAGE__->setup;



1;
