#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use AnyEvent;
use AsyncUtil qw[ delay_me ];

BEGIN {
    use_ok('Promises', 'collect');
}

my $cv = AnyEvent->condvar;

my $p0 = delay_me( 1 );
my $p1 = delay_me( 2 );

collect( $p0, $p1 )->then(
    sub { $cv->send( @_ ) },
    sub { $cv->croak( 'ERROR' ) }
);

diag "Delaying for 2 seconds ...";

is( $p0->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 0' );
is( $p1->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 1' );

is_deeply(
    [ $cv->recv ],
    [
        [ 'resolved after 1' ],
        [ 'resolved after 2' ]
    ],
    '... got the expected values back'
);

is( $p0->status, Promises::Deferred->RESOLVED, '... got the right status in promise 0' );
is( $p1->status, Promises::Deferred->RESOLVED, '... got the right status in promise 1' );

done_testing;