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

my $cv0 = AnyEvent->condvar;
my $cv1 = AnyEvent->condvar;

my $p0 = delay_me( 2 );

$p0->then(
    sub { $cv0->send( 'ZERO', @_, $p0->status, $p0->result ) },
    sub { $cv0->croak( 'ERROR' ) }
);

diag "Delaying for 2 seconds ...";

is( $p0->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 0' );

is_deeply(
    [ $cv0->recv ],
    [
        'ZERO',
        'resolved after 2',
        Promises::Deferred->RESOLVING,
        [ 'resolved after 2' ]
    ],
    '... got the expected values back'
);

is( $p0->status, Promises::Deferred->RESOLVED, '... got the right status in promise 0' );

$p0->then(
    sub { $cv1->send( 'ONE', @_, $p0->status, $p0->result ) },
    sub { $cv1->croak( 'ERROR' ) }
);

is_deeply(
    [ $cv1->recv ],
    [
        'ONE',
        'resolved after 2',
        Promises::Deferred->RESOLVING,
        [ 'resolved after 2' ]
    ],
    '... got the expected values back'
);

is( $p0->status, Promises::Deferred->RESOLVED, '... got the right status in promise 0' );

done_testing;