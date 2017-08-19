#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::Requires 'AnyEvent';

use Test::More;
use AnyEvent;
use AsyncUtil qw[ delay_me ];

BEGIN {
    use_ok('Promises');
}

my $cv = AnyEvent->condvar;
my $p0 = delay_me( 0.1 );

$p0->then(
    sub { $cv->send( 'ZERO', @_, $p0->status, $p0->result ) },
    sub { $cv->croak( 'ERROR' ) }
);

diag "Delaying for 0.1 second ...";

is( $p0->status, Promises::Deferred->IN_PROGRESS, '... got the right status' );

is_deeply(
    [ $cv->recv ],
    [
        'ZERO',
        'resolved after 0.1',
        Promises::Deferred->RESOLVED,
        [ 'resolved after 0.1' ]
    ],
    '... got the expected values back'
);

is( $p0->status, Promises::Deferred->RESOLVED, '... got the right status' );

subtest 'checking predicates' => sub {
    # should be true
    ok $p0->$_, $_ for qw/ is_resolved is_fulfilled is_done /;

    # should be false
    ok !$p0->$_, $_ for qw/ is_rejected is_unfulfilled is_in_progress /;
};

done_testing;
