#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use AnyEvent;
use AsyncUtil qw[ delay_me_error ];

BEGIN {
    use_ok('Promises');
}

my $cv = AnyEvent->condvar;
my $p0 = delay_me_error( 2 );

$p0->then(
    sub { $cv->croak( 'We are expecting an error here, so this shouldn\'t be called' ) },
    sub { $cv->send( 'ERROR', @_, $p0->status, $p0->result ) }
);

diag "Delaying for 2 seconds ...";

is( $p0->status, Promises::Deferred->IN_PROGRESS, '... got the right status' );

is_deeply(
    [ $cv->recv ],
    [
        'ERROR',
        'rejected after 2',
        Promises::Deferred->REJECTING,
        [ 'rejected after 2' ]
    ],
    '... got the expected values back'
);

is( $p0->status, Promises::Deferred->REJECTED, '... got the right status' );

done_testing;