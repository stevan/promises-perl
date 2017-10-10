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

    Promises->_set_backend([$backend]);

    return use_module( 'Promises::Test::' . $backend )->new;
}


1;
