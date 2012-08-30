package SessionTestApp::Logger;
use Moose;
use MooseX::Storage;

with Storage ( format => 'JSON' );

has debug => (
    is => 'rw'
);

has error => (
    is => 'rw'
);

1;
