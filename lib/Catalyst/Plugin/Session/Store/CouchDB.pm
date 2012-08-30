package Catalyst::Plugin::Session::Store::CouchDB;

use Moose;
use namespace::autoclean;
use Catalyst::Plugin::Session::Store::CouchDB::Client;
use Catalyst::Exception;
use Module::Runtime qw(use_module);

extends 'Catalyst::Plugin::Session::Store';

our $VERSION = '0.01';

has uri => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_uri',
);

has dbname => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_dbname',
);

has dbconnection => (
    isa     => 'Catalyst::Plugin::Session::Store::CouchDB::Client',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_dbconnection',
);

has debug_flag => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_debug_flag',
);

sub _build_dbconnection {
    my $self = shift;
    my $uri  = $self->uri;
    my $name = $self->dbname;
    
    $self->log->debug( "Trying to connect to db '$name' at '$uri'." )
        if $self->debug_flag;

    my $db = eval {
		Catalyst::Plugin::Session::Store::CouchDB::Client->new( 
            uri   => $uri, 
            db    => $name,
            debug => $self->debug_flag,
            log   => $self->log,
        );
	};
    if ( $@ ) {
        Catalyst::Exception->throw( error => $@ );
    }
    return $db;
}

sub _build_uri {
    my $self = shift;

    my $cfg = $self->_session_plugin_config;
    if ( exists $cfg->{ uri } ) {
        return $cfg->{ uri };
    }
    else {
        return 'http://localhost:5984/';
    }
}

sub _build_dbname {
    my $self = shift;

    my $cfg = $self->_session_plugin_config;
    if ( exists $cfg->{ dbname } ) {
        return $cfg->{ dbname };
    }
    else {
        return 'catalyst';
    }
}

sub _build_debug_flag {
    my $self = shift;

    my $cfg = $self->_session_plugin_config;
    if ( exists $cfg->{ debug } ) {
        return $cfg->{ debug };
    }
    else {
        return;
    }
}

sub get_session_data {
    my ( $self, $key ) = @_;
    my $thawed_session;

    $self->log->debug( "Trying to retrieve session '$key'" )
        if $self->debug_flag;

    if ( my $session = $self->dbconnection->retrieve( $key ) ) {
        $thawed_session = $self->thaw_data( $session );
    }

    return $thawed_session;
}

sub store_session_data {
    my ( $self, $key, $data ) = @_;
    my $doc;
     
    $self->log->debug( "Trying to store session '$key'" )
        if $self->debug_flag;

    $doc = $self->freeze_data( $data );
    return $self->dbconnection->store( $key => $doc );
}

sub delete_session_data {
    my ( $self, $key ) = @_;

    $self->log->debug( "Trying to delete session '$key'" )
        if $self->debug_flag;

    $self->dbconnection->delete( $key );
}

sub delete_expired_sessions {
    my ( $self ) = @_;
    
    Catalyst::Exception->
        throw( error => 'delete_expired_sessions is not yet implemented' );
       
    $self->dbconnection->delete_expired_docs();
}

sub freeze_data {
    my ( $self, $data ) = @_;
    my $frozen;

    if ( my $data_ref = ref $data ) {
        if ( $data_ref eq 'HASH' ) {
            foreach my $k ( keys %$data ) {
                $frozen->{ $k } = $self->freeze_data( $data->{ $k } );
            }
        }
        elsif ( $data_ref eq 'ARRAY' ) {
            foreach my $el ( @$data ) {
                push @$frozen, $self->freeze_data( $el );
            }
        }
        elsif ( $data->can( 'pack' ) ) {
            $frozen = $data->pack;
        }
        else {
            die "Don't know how to freeze object of type $data_ref.";
        }
    }
    else {
        $frozen = $data;
    }

    return $frozen;
}

sub thaw_data {
    my ( $self, $data ) = @_;

    my $thawed;

    if ( ref $data eq 'HASH' ) {
        if ( $data->{ __CLASS__ } ) {
            $thawed = use_module( $data->{ __CLASS__ } )->unpack( $data );
        }
        else {
            foreach ( keys %$data ) {
                $thawed->{ $_ } = $self->thaw_data( $data->{ $_ } );
            }
        }
    }
    elsif ( ref $data eq 'ARRAY' ) {
        foreach ( @$data ) {
            push @$thawed, $self->thaw_data( $_ );
        }
    }
    else {
        $thawed = $data;
    }

    return $thawed;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Catalyst::Plugin::Session::Store::CouchDB - CouchDB session store for Catalyst

=head1 SYNOPSIS

In your MyApp.pm:

    use Catalyst qw/
        Session
        Session::Store::CouchDB
        Session::State::Cookie    # or similar
    /;

and in your MyApp.conf:

    <Plugin::Session>
        uri https://db.example.com:1234/  # defaults to 'http://localhost:5984/'
        dbname test                       # defaults to 'catalyst'
    </Plugin::Session>

and, finally, in your controllers:

    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::CouchDB> is a session storage plugin using
CouchDB (L<http://www.couchdb.org>) as it's backend.

=head1 AUTHOR


=head1 COPYRIGHT


=cut

