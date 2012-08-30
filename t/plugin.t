use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::Exception;

use lib 't/lib';
use SessionTestApp::Logger;

BEGIN { use_ok 'Catalyst::Plugin::Session::Store::CouchDB' }

my $default_couchdb_uri = 'http://localhost:5984/';

# TODO: check whether a db is available or even: mock the db 

test_new();
test_store_session_data();
test_delete_expired_sessions();

done_testing();


sub test_store_session_data {
    my $couchdb_conn = get_new_db_instance( { uri => $default_couchdb_uri } );

    my $time = time;
    my $to_be_put_into_db = { 
        foobar => 'pudding', 
        arref  => [ 1, 2, 3, 6 ], 
        href   => { foo => 'bar' },  
        href2  => { baz => [ -1, -2, -10 ] },
    };

    my $new_expires = $time + 1000;
    ok( $couchdb_conn->store_session_data( "expires:test_session_id", $new_expires ), 'store returns true' );
    ok( $couchdb_conn->store_session_data( "session:test_session_id", $to_be_put_into_db ), 'store returns true' );

    my $result = $couchdb_conn->get_session_data( "session:test_session_id" );
    is_deeply( $result, $to_be_put_into_db, "session-content should equal the data we put in" );

    $result = $couchdb_conn->get_session_data( "expires:test_session_id" );
    is_deeply( $result, $new_expires, "expires session-content should equal the data we put in" );

    $couchdb_conn->delete_session_data( 'session:test_session_id' );
    $result = $couchdb_conn->get_session_data( 'session:test_session_id' );
    is($result, undef, 'session is gone after deletion.' );

    $couchdb_conn->delete_session_data( 'expires:test_session_id' );
    $result = $couchdb_conn->get_session_data( 'expires:test_session_id' );
    is($result, undef, 'expires-session is gone after deletion.' );
}


sub test_new {
    my $couchdb_conn = get_new_db_instance( {
            uri    => 'http://example.com:1234/',
            dbname => 'perl-storable-couchdb'
    } );

    isa_ok( $couchdb_conn, "Catalyst::Plugin::Session::Store::CouchDB" );
    isa_ok( $couchdb_conn, "Catalyst::Plugin::Session::Store" );

    is( $couchdb_conn->uri,    'http://example.com:1234/', 'uri is correct' );
    is( $couchdb_conn->dbname, 'perl-storable-couchdb',    'dbname is correct' );

    $couchdb_conn = get_new_db_instance( { uri => $default_couchdb_uri } );
    isa_ok( $couchdb_conn, "Catalyst::Plugin::Session::Store::CouchDB" );
    isa_ok( $couchdb_conn, "Catalyst::Plugin::Session::Store" );

    is( $couchdb_conn->uri, $default_couchdb_uri, 'uri is correct' );
    is( $couchdb_conn->dbname, 'catalyst', 'dbname is correct' );

    $couchdb_conn = get_new_db_instance( { uri => 'http://example.com:1234/foobar', } );
    isa_ok( $couchdb_conn, "Catalyst::Plugin::Session::Store::CouchDB" );
    isa_ok( $couchdb_conn, "Catalyst::Plugin::Session::Store" );

    is( $couchdb_conn->uri, 'http://example.com:1234/foobar', 'uri is correct' );
    is( $couchdb_conn->dbname, 'catalyst', 'dbname is correct' );

    $couchdb_conn = get_new_db_instance( { uri => 'http://300.300.300.300:1234/foobar', } );
    isa_ok( $couchdb_conn, "Catalyst::Plugin::Session::Store::CouchDB" );
    isa_ok( $couchdb_conn, "Catalyst::Plugin::Session::Store" );

    is( $couchdb_conn->uri, 'http://300.300.300.300:1234/foobar', 'uri is correct' );
    is( $couchdb_conn->dbname, 'catalyst', 'dbname is correct' );

    dies_ok {
        $couchdb_conn->store_session_data( "session:test_session_id", { foo => 'bar' } );
    } "connecting to a db that doesn't exists should trigger an exception.";

}

sub test_delete_expired_sessions {
    my $couchdb_conn = get_new_db_instance( { uri => $default_couchdb_uri } );

    dies_ok { $couchdb_conn->delete_expired_sessions; } 'unimplemented method triggers exception';
}


sub get_new_db_instance {
    my $args = shift;

    $args->{ debug } = 1;

    my $c_meta = Class::MOP::Class->create_anon_class( 
        superclasses => [ qw/
            Catalyst::Plugin::Session::Store::CouchDB
            Moose::Object
        / ] );

    my $logger = SessionTestApp::Logger->new;
    $c_meta->add_method( log                    => sub { $logger } );
    $c_meta->add_method( _session_plugin_config => sub { {} } );

    return $c_meta->name->new( $args );
}


