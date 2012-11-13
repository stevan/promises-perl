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

my $p0 = delay_me( 1 );
my $p1 = delay_me( 2 );

$p1->then(
    sub { $cv1->send( 'ONE', @_, $p1->status, $p1->result ) },
    sub { $cv1->croak( 'ERROR' ) }
);

$p0->then(
    sub { $cv0->send( 'ZERO', @_, $p0->status, $p0->result ) },
    sub { $cv0->croak( 'ERROR' ) }
);

diag "Delaying for 1 second ...";

is( $p0->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 0' );
is( $p1->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 1' );

is_deeply(
    [ $cv0->recv ],
    [
        'ZERO',
        'resolved after 1',
        Promises::Deferred->RESOLVING,
        [ 'resolved after 1' ]
    ],
    '... got the expected values back'
);

diag "Delaying for 1 more second ...";

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
is( $p1->status, Promises::Deferred->RESOLVED, '... got the right status in promise 1' );

done_testing;