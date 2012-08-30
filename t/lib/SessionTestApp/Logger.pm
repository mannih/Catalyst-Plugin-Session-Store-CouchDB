package SessionTestApp::Logger;
use Moose;

has debug => (
    is => 'rw'
);

has error => (
    is => 'rw'
);

1;
