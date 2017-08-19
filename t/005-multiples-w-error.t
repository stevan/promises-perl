#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Requires 'AnyEvent';

use AnyEvent;
use AsyncUtil qw[ delay_me delay_me_error ];

BEGIN {
    use_ok('Promises');
}

my $cv0 = AnyEvent->condvar;
my $cv1 = AnyEvent->condvar;

my $p0 = delay_me_error( 0.1 );
my $p1 = delay_me( 0.2 );

$p1->then(
    sub { $cv1->send( 'ONE', @_, $p1->status, $p1->result ) },
    sub { $cv1->croak( 'ERROR' ) }
);

$p0->then(
    sub { $cv0->croak( 'We are expecting an error here, so this shouldn\'t be called' ) },
    sub { $cv0->send( 'ERROR', @_, $p0->status, $p0->result ) }
);

diag "Delaying for 0.1 second ...";

is( $p0->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 0' );
is( $p1->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 1' );

is_deeply(
    [ $cv0->recv ],
    [
        'ERROR',
        'rejected after 0.1',
        Promises::Deferred->REJECTED,
        [ 'rejected after 0.1' ]
    ],
    '... got the expected values back'
);

diag "Delaying for 0.1 more second ...";

is_deeply(
    [ $cv1->recv ],
    [
        'ONE',
        'resolved after 0.2',
        Promises::Deferred->RESOLVED,
        [ 'resolved after 0.2' ]
    ],
    '... got the expected values back'
);

is( $p0->status, Promises::Deferred->REJECTED, '... got the right status in promise 0' );
is( $p1->status, Promises::Deferred->RESOLVED, '... got the right status in promise 1' );

done_testing;
