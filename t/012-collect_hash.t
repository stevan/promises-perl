#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Requires 'AnyEvent';

use AnyEvent;
use AsyncUtil qw[ delay_me ];

use Promises qw/ collect_hash deferred /;

my $cv = AnyEvent->condvar;

my $p0 = delay_me( 0.1 );
my $p1 = delay_me( 0.2 );

collect_hash( p0 => $p0, p1 => $p1, p3 => 'constant' )->then(
    sub { $cv->send( @_ ) },
    sub { $cv->croak( 'ERROR' ) }
);

diag "Delaying for 0.2 seconds ...";

is( $p0->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 0' );
is( $p1->status, Promises::Deferred->IN_PROGRESS, '... got the right status in promise 1' );

is_deeply(
    [ $cv->recv ],
    [
     p0 => 'resolved after 0.1' ,
      p1 => 'resolved after 0.2' ,
      p3 => 'constant',
    ] ,
    '... got the expected values back'
);

is( $p0->status, Promises::Deferred->RESOLVED, '... got the right status in promise 0' );
is( $p1->status, Promises::Deferred->RESOLVED, '... got the right status in promise 1' );

$p0 = collect_hash( bar => deferred->resolve('foo')->promise )->then(
    sub {
        is shift()->[0], 'foo', 'Presolved collect';
    }
);

$p0 = collect_hash( bar => deferred->reject('foo')->promise )->catch(
    sub {
        is shift(), 'foo', 'Prerejected collect';
    }
);



done_testing;
