#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use AnyEvent;
use AsyncUtil qw[ delay_me delay_me_error ];

BEGIN {
    use_ok('Promises', 'collect');
}

my $cv = AnyEvent->condvar;

my $p0 = delay_me_error( 0.1 );
my $p1 = delay_me( 0.2 );

collect( $p0, $p1 )->then(
    sub { $cv->croak( 'We are expecting an error here, so this shouldn\'t be called' ) },
    sub { $cv->send( 'ERROR' ) }
);

diag "Delaying for 0.2 seconds ...";

is( $p0->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 0' );
is( $p1->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 1' );

is_deeply(
    [ $cv->recv ],
    [ 'ERROR' ],
    '... got the expected values back'
);

is( $p0->status, Promises::Deferred->REJECTED, '... got the right status in promise 0' );
is( $p1->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 1' );

done_testing;