package Catalyst::Plugin::Session::Store::CouchDB;

use Moose;
use namespace::autoclean;
use Catalyst::Plugin::Session::Store::CouchDB::Client;
use Catalyst::Exception;
use Module::Runtime qw(use_module);
use Storable qw/ freeze thaw /;

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
            uri    => $uri, 
            dbname => $name,
            debug  => $self->debug_flag,
            log    => $self->log,
        );
	};

    if ( $@ ) {
        Catalyst::Exception->throw( error => $@ );
    }

    $db->create_database;

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
        return 'catalyst-session-store';
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
            $frozen = { __STORABLE_FROZEN__ => freeze $data };
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
        elsif ( $data->{ __STORABLE_FROZEN__ } ) {
            $thawed = thaw $data->{ __STORABLE_FROZEN__ };
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
        Session::State::Cookie
    /;

and in your MyApp.conf:

    <Plugin::Session>
        uri https://db.example.com:1234/  # defaults to 'http://localhost:5984/'
        dbname test                       # defaults to 'catalyst-session-store'
    </Plugin::Session>

and, finally, in your controllers:

    $c->session->{ foo } = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::CouchDB> is a session storage plugin using
CouchDB (L<http://www.couchdb.org>) as its backend. It is using its own client
library to talk to the CouchDB instance.

=head1 CONFIGURATION

Three options can be set, but only the first two are really important.

=head2 uri

The URI to your CouchDB instance. This defaults to http://localhost:5984/ 

=head2 dbname

The name of the database in which your sessions should be stored. If the database
does not yet exist, it will be created when the first request is made. This
also means that if you start your Catalyst application, store or retrieve a session
and then delete the database, you app will die.
The default for this option is 'catalyst-session-store'.

=head2 debug_flag

Set this to a true value if you need extensive logging of what happens when
this module stores or retrieves sessions. This should only be necessary when
reporting bugs.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Manni Heumann

=head1 COPYRIGHT

Copyright (c) 2012, Manni Heumann

=cut

