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
test_freeze_thaw();

done_testing();


sub test_freeze_thaw {
    my $cdb = get_new_db_instance( { uri => $default_couchdb_uri } );
    
    my $object1 = SessionTestApp::Logger->new(
        debug => 'some debug value',
        error => 'some error value',
    );
    my $frozen = $cdb->freeze_data( $object1 );
    ok( $frozen, 'freeze_data froze something' );
    my $thawed = $cdb->thaw_data( $frozen );
    ok( $thawed, 'thaw_data thawed something' );
    isa_ok( $thawed, 'SessionTestApp::Logger' );
    is( $thawed->debug, 'some debug value', 'debug returns correct value' );
    is( $thawed->error, 'some error value', 'error returns correct value' );
    is( ref $frozen, ref {}, 'Freezing a Storage consuming class yields a hash-ref' );
    ok( exists $frozen->{ __CLASS__ }, 'We have the needed __CLASS__ key' );

    my $struct = [ 1, 2, { foo => 'bar' }, [ [ 3, 4 ], [ 5, 6 ], { baz => 'zab' } ] ];
    $thawed = $cdb->thaw_data( $cdb->freeze_data( $struct ) );
    is_deeply( $thawed, $struct, 'freeze and thaw return original structure' );

    dies_ok { $cdb->freeze_data( Catalyst::Plugin::Session::Store::CouchDB->new ) } 'freeze_data dies when it cannot freeze an object';
}

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


