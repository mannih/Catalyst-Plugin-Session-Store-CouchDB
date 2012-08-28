package SessionTestApp::Controller::Root;
use Moose;
use namespace::autoclean;

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

__PACKAGE__->meta->make_immutable;

1;
