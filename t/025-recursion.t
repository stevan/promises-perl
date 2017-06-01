#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Requires 'AnyEvent';

use Scalar::Util qw(weaken);
use AnyEvent;

BEGIN {
    use_ok 'Promises::Deferred';
    use_ok 'Promises::Deferred::AE';
    use Promises qw/deferred/;
}

our ( $Max, $Live, $Iter );

#      backend     type    iter max
test( 'Default',  'resolve', 5,  7 );
test( 'Default',  'resolve', 10, 7 );
test( 'Default',  'reject',  5,  7 );
test( 'Default',  'reject',  10, 7 );
test( 'AE',       'resolve', 5,  5 );
test( 'AE',       'resolve', 10, 5 );
test( 'AE',       'reject',  5,  5 );
test( 'AE',       'reject',  10, 5 );

#===================================
sub test {
#===================================
    my ( $backend, $type, $iter, $max ) = @_;

    $Iter = $iter;

    wrap_deferred();
    my $cv   = AnyEvent->condvar;

    Promises::Deferred->_set_backend([$backend]);

    test_loop( $type eq 'reject' )
        ->then( sub { $cv->send(@_) }, sub { $cv->send(@_) } );

    is $cv->recv, $type . ':' . $max, "$backend - $type - $iter";

}

#===================================
sub test_loop {
#===================================
    my $fail  = shift;

    my $d = deferred;
    my $weak_loop;
    my $loop = sub {
        if ( --$Iter == 0 ) {
            $d->resolve( 'resolve:' . $Max );
            return;
        }

        # async promise
        a_promise()

            # should we fail
            ->then( sub { die if $fail && $Iter == 1 } )

            # noop
            ->then( sub {@_} )

            # loop or fail
            ->done(
            $weak_loop,
            sub {
                $d->reject( 'reject:' . $Max );
            }
            );
    };
    weaken( $weak_loop = $loop );
    $loop->();
    return $d->promise;
}

my $wrap_once;
sub wrap_deferred {
    no strict 'refs';
    no warnings 'once', 'redefine';
    if (!$wrap_once++) {
        my $old_sub= \&Promises::Deferred::new;
        *Promises::Deferred::new= sub {
            $Live++;
            $Max= $Live if $Live > $Max;
            goto &$old_sub;
        };
        *Promises::Deferred::DESTROY= sub {
            $Live--;
        };
    }
    $Live= 0;
    $Max= 0;
}

#===================================
sub a_promise {
#===================================
    my $d = deferred;
    my $w;
    $w = AnyEvent->timer(
        after => 0,
        cb    => sub {
            $d->resolve('OK');
            undef $w;
        }
    );
    $d->promise;
}

done_testing;
