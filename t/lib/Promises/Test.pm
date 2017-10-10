package Promises::Test;

use strict;
use warnings;

use Promises;
use Module::Runtime qw/ use_module /;

sub backend {
    my $backend = shift;

    $SIG{ALRM} = sub {
        Test::More::BAIL_OUT( 'test timed out' );
    };

    alarm( shift || 10 );

    my $x = eval {
        Promises->_set_backend([$backend])
    } or return;

    return use_module( 'Promises::Test::' . $backend )->new;
}


1;
