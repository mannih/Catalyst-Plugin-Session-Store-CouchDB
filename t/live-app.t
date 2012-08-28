use strict;
use warnings;

use Test::More;
use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";


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


done_testing;
