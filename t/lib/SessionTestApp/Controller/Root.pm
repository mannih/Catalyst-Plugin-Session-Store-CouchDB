package SessionTestApp::Controller::Root;
use Moose;
use namespace::autoclean;
use SessionTestApp::Logger;
use Catalyst::Plugin::Session::Store::CouchDB;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');


sub set_value : Local Args( 1 ) {
    my ( $self, $c, $arg ) = @_;
    
    $c->session->{ first_value } = $arg;
    $c->response->body( $arg );
}

sub get_value : Local Args( 0 ) {
    my ( $self, $c ) = @_;

    $c->response->body( $c->session->{ first_value } );
}

sub delete_session : Local Args( 0 ) {
    my ( $self, $c ) = @_;

    $c->delete_session( 'reason' );
    $c->response->body( '' );
}

sub store_storage_object : Local Args( 0 ) {
    my ( $self, $c ) = @_;

    my $obj = SessionTestApp::Logger->new(
        debug => 'some weird debug value',
        error => 'some sort of error value',
    );

    $c->session->{ storage_object } = $obj;
    $c->response->body( '' );
}

sub retrieve_storage_object : Local Args( 0 ) {
    my ( $self, $c ) = @_;

    my $obj = $c->session->{ storage_object };

    $c->response->content_type( 'text/plain' );
    my $body = 'debug:' . $obj->debug . "\n";
    $body .= 'error:' . $obj->error . "\n";

    $c->response->body( $body );
}

sub store_storable_object : Local Args( 0 ) {
    my ( $self, $c ) = @_;

    my $obj = Catalyst::Plugin::Session::Store::CouchDB->new(
        uri        => 'this is not a URI',
        dbname     => 'and this is not a dbname',
        debug_flag => 4711,
    );

    $c->session->{ storable_object } = $obj;
    $c->response->body( '' );
}

sub retrieve_storable_object : Local Args( 0 ) {
    my ( $self, $c ) = @_;

    my $obj = $c->session->{ storable_object };

    $c->response->content_type( 'text/plain' );
    my $body = 'uri:' . $obj->uri . "\n";
    $body .= 'dbname:' . $obj->dbname . "\n";
    $body .= 'debug_flag:' . $obj->debug_flag . "\n";

    $c->response->body( $body );
}

__PACKAGE__->meta->make_immutable;

1;
