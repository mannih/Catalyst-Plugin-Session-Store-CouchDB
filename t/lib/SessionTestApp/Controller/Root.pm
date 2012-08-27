package SessionTestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub step_one : Local :Args(1) {
    my ( $self, $c, $arg ) = @_;
    
    $c->session->{ first_value } = $arg;
    $c->response->redirect( '/step_two' );
    $c->detach;
}

sub step_two : Local Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body( $c->session->{ first_value } );
    $c->session->{ second_value } = reverse $c->session->{ first_value };
}


__PACKAGE__->meta->make_immutable;

1;
