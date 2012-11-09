#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use AnyEvent;
use AsyncUtil qw[ delay_me ];

BEGIN {
    use_ok('Promises');
}

my $cv = AnyEvent->condvar;
my $p0 = delay_me( 2 );

$p0->then(
    sub { $cv->send( 'ZERO', @_, $p0->status, $p0->result ) },
    sub { $cv->croak( 'ERROR' ) }
);

diag "Delaying for 2 seconds ...";

is( $p0->status, Promises::Deferred->IN_PROGRESS, '... got the right status' );

is_deeply(
    [ $cv->recv ],
    [
        'ZERO',
        'resolved after 2',
        Promises::Deferred->IN_PROGRESS,
        [ 'resolved after 2' ]
    ],
    '... got the expected values back'
);

is( $p0->status, Promises::Deferred->RESOLVED, '... got the right status' );

done_testing;