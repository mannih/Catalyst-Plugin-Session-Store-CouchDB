package Catalyst::Plugin::Session::Store::CouchDB::Client;

use Moose;
use namespace::autoclean;
use TryCatch;
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use JSON;
use Encode qw( encode_utf8 );


has user_agent => (
    isa     => 'LWP::UserAgent',
    is      => 'rw',
    lazy    => 1,
    builder => '_build_user_agent',
);

has uri => (
    isa     => 'Str',
    is      => 'ro',
    default => 'http://localhost:5984',
);

has db => (
    isa     => 'Str',
    is      => 'rw',
    default => 'read_write_test_range',
);

has doc => (
    is      => 'rw',
);

has doc_id => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has doc_rev => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has debug => (
    is       => 'ro',
    required => 1,
);

has encode => (
    is       => 'ro',
    default => 1,
);

has log => (
    is       => 'ro',
    required => 1,
);

sub _build_user_agent {
    my $self = shift;

    my $ua = LWP::UserAgent->new;
    $ua->timeout( 10 );

    return $ua;
}

sub doc_exists {
    my $self   = shift;
    my $doc_id = shift;

    try {
        my $doc = $self->_send_db_request( "GET", $doc_id )->content;
        $self->doc( from_json( $doc ) );
        $self->doc_id( $self->doc->{ _id } );
        $self->doc_rev( $self->doc->{ _rev } );
        $self->log->debug( "Yes, document with id '$doc_id' exists." )
            if $self->debug;
        return 1;
    }
    catch( $e ) {
        $self->log->debug( "Document '$doc_id' does not exist." )
            if $self->debug;
        $self->doc( undef );
        $self->doc_id( '' );
        $self->doc_rev( '' );
        return;
    }
}

sub make_request {
    my $self             = shift;
    my $method           = shift;
    my $request_data     = shift;
    my $url_param_string = shift;

    my %headers = (
        Content_Type => 'application/json',
    );

    my $data;
    if ( defined $request_data ) {
        $headers{ Content_Length } = length $request_data;
        
        if($self->encode){
            $data = encode_utf8( $request_data );
	    }
	    else{
            $data = $request_data;
	    }
    }
    my $h = HTTP::Headers->new( %headers );

    my $uri = $self->uri . "/" . $self->db;
    if ( defined $url_param_string ) {
        $uri .= '/' . $url_param_string;
    }

    my $r = HTTP::Request->new( $method, $uri, $h, $data );

    $self->log->debug( "Performing HTTP request of type '$method'." )
        if $self->debug;

    my $response = $self->user_agent->request( $r );

    return $response;
}


sub _send_db_request {
    my $self             = shift;
    my $method           = shift;
    my $url_param_string = shift;
    my $request_data     = shift;

    my $response = $self->make_request( $method, $request_data, $url_param_string );

    if ( $method eq "GET" ) {
        if ( $response->is_success ) {
            die "no such doc" if $response =~ /not found/;
        }
    }

    unless ( $response->is_success ) {
        my $msg = sprintf "Could not send db request %s (%s) to %s db says: '%s'", 
                    $method, $url_param_string, $self->uri, $response->status_line;
        if ( $msg !~ m/'404 Object Not Found'/ ) {
            $self->log->error( $msg );
        }
        elsif ( $self->debug ) {
            $self->log->debug( $msg );
        }
        die $msg;
    }

    return $response;
}

#############################################################
#### interface-methoden, an Storable::CouchDB angelehnt######
#############################################################

sub retrieve {
    my $self = shift;
    my $key  = shift;
    my $result;

    $self->doc_exists( $key );

    if ( ref( $self->doc ) eq "HASH" ) {
        $result = $self->doc->{ data };
    }
    else {
        $result = $self->doc;
    }

    return $result;
}

sub store {
    my $self        = shift;
    my $couchdb_key = shift;
    my $data        = shift;

    $self->log->debug( "storing session '$couchdb_key'. Our doc_id is '" . $self->doc_id . "'" )
        if $self->debug;

    my $param  = {
        data => $data,
    };

    if ( $self->doc_exists( $couchdb_key ) ) {
        $param->{ _rev } = $self->doc_rev;
    }
    else {
        $self->doc_id( $couchdb_key );
    }

    my $param_as_json = to_json($param);
    my $response = $self->_send_db_request( 'PUT', $self->doc_id, $param_as_json);

    return $response->is_success;
}

sub delete {
    my $self = shift;
    my $key  = shift;

    unless ( ref( $key ) ) {
        unless ( $key eq $self->doc_id ) {
            $self->doc_exists( $key );
        }
        if ( $self->doc_id && $self->doc_rev ) {
            $self->_send_db_request( "DELETE", $self->doc_id . "?rev=" . $self->doc_rev );

            $self->doc( {} );
            $self->doc_rev( '' );
            $self->doc_id( '' );
        }
    }
    elsif ( ref( $key ) eq "ARRAY" ) {
        foreach ( @$key ) {
            $self->delete( $_ );
        }
    }
    else {
        ;
    }
    return undef;
}

sub delete_expired_docs {
    my $self = shift;
}

1;
