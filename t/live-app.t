use strict;
use warnings;

use Test::More;
use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";
use IO::Socket::INET;


SKIP: {
    skip 'No CouchDB instance found on localhost:5984.', 26 
        unless IO::Socket::INET->new( '127.0.0.1:5984' );

    my $ua = Test::WWW::Mechanize::Catalyst->new;

    $ua->get_ok( 'http://localhost/set_value/this_string_should_be_stored', 'request to set_value' );
    $ua->get_ok( 'http://localhost/get_value', 'request to get_value' );
    $ua->content_contains( 'this_string_should_be_stored' );
    $ua->get_ok( 'http://localhost/delete_session', 'request to delete_session' );
    $ua->get_ok( 'http://localhost/get_value', 'request to get_value' );
    $ua->content_lacks( 'this_string_should_be_stored' );

    $ua->get_ok( 'http://localhost/set_value/another_string', 'request to set_value' );
    $ua->get_ok( 'http://localhost/get_value', 'request to get_value' );
    $ua->content_contains( 'another_string' );
    $ua->get_ok( 'http://localhost/set_value/final_string_value', 'request to set_value' );
    $ua->get_ok( 'http://localhost/get_value', 'request to get_value' );
    $ua->content_contains( 'final_string_value' );

    $ua->get_ok( 'http://localhost/delete_session', 'request to delete_session' );
    $ua->get_ok( 'http://localhost/get_value', 'request to get_value' );
    $ua->content_lacks( 'this_string_should_be_stored' );
    $ua->content_lacks( 'final_string_value' );
    $ua->content_lacks( 'another_string' );

    $ua->get_ok( 'http://localhost/store_storage_object', 'request to store_storage_object' );
    $ua->get_ok( 'http://localhost/retrieve_storage_object', 'request to retrieve_storage_object' );
    $ua->content_contains( 'debug:some weird debug value' );
    $ua->content_contains( 'error:some sort of error value' );

    $ua->get_ok( 'http://localhost/store_storable_object', 'request to store_storable_object' );
    $ua->get_ok( 'http://localhost/retrieve_storable_object', 'request to retrieve_storable_object' );
    $ua->content_contains( 'uri:this is not a URI' );
    $ua->content_contains( 'dbname:and this is not a dbname' );
    $ua->content_contains( 'debug_flag:4711' );
}

done_testing;
