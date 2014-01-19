#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Scalar::Util qw(weaken);
use AnyEvent;

BEGIN {
    use_ok 'Promises::Deferred';
    use_ok 'Promises::Deferred::AE';
}

our ( $Max, $Live, $Iter );

#      class                 type        iter max
test( 'Promises::Deferred',     'resolve', 5,  8 );
test( 'Promises::Deferred',     'resolve', 10, 8 );
test( 'Promises::Deferred',     'reject',  5,  8 );
test( 'Promises::Deferred',     'reject',  10, 8 );
test( 'Promises::Deferred::AE', 'resolve', 5,  5 );
test( 'Promises::Deferred::AE', 'resolve', 10, 5 );
test( 'Promises::Deferred::AE', 'reject',  5,  5 );
test( 'Promises::Deferred::AE', 'reject',  10, 5 );

#===================================
sub test {
#===================================
    my ( $class, $type, $iter, $max ) = @_;

    $Iter = $iter;

    my $wrap = wrap_class($class);
    my $cv   = AnyEvent->condvar;

    test_loop( $wrap, $type eq 'reject' )
        ->then( sub { $cv->send(@_) }, sub { $cv->send(@_) } );

    is $cv->recv, $type . ':' . $max, "$class - $type - $iter";

}

#===================================
sub test_loop {
#===================================
    my $class = shift;
    my $fail  = shift;

    my $d = $class->new;
    my $weak_loop;
    my $loop = sub {
        if ( --$Iter == 0 ) {
            $d->resolve( 'resolve:' . $Max );
            return;
        }

        # async promise
        a_promise($class)

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

#===================================
sub wrap_class {
#===================================
    my $class         = shift;
    my $wrapped_class = $class . '::Track';

    unless ( $wrapped_class->can('new') ) {
        eval <<CLASS or die $!;
    package $wrapped_class;
    use parent '$class';
    sub new {
        \$Live++;
        \$Max = \$Live if \$Live > \$Max;
        ${wrapped_class}->SUPER::new
    }

    sub DESTROY { \$Live-- }

    1

CLASS
    }
    $Live = 0;
    $Max  = 0;
    return $wrapped_class;
}

#===================================
sub a_promise {
#===================================
    my ($class) = @_;
    my $d = $class->new;
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
