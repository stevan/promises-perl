#!perl

use strict;
use warnings;

use lib 't/lib';
use NoEV;
use Test::More;
use Test::Fatal;

BEGIN {
    if (!eval { require AnyEvent; AnyEvent->import; 1 }) {
        plan skip_all => "AnyEvent is required for this test";
    }
    use_ok 'Promises::Deferred::AnyEvent';
    use Promises 'deferred', backend => ['AnyEvent'];
}

my @out;

my $cv = AE::cv;
is( exception {
        a_promise()

            # Resolve
            ->then( sub {"1: OK"} )

            # Resolve then die
            ->then( sub { push @out, @_; die "2: OK\n" } )

            # Reject and resolve
            ->then(
            sub { push @out, "2: Not OK" },
            sub { push @out, @_; "3: OK" }
            )

            # Resolve then die
            ->then(
            sub { push @out, @_; die "4: OK\n" },
            sub { push @out, @_, "3: Not OK" }
            )

            # Reject then die
            ->then(
            sub { push @out, "4: Not OK" },
            sub { push @out, @_; die "5: OK\n" }
            )

            # done then die
            ->done(
            sub { push @out, "4: Not OK" },
            sub { push @out, @_; die "Final\n" }
            );

        my $w = AE::timer( 1, 0, sub { $cv->send } );
        $cv->recv;
    },
    "Final\n",
    "Exception in AnyEvent PP done dies"
);

is $out[0], '1: OK',   "Resolve";
is $out[1], "2: OK\n", "Resolve then die";
is $out[2], '3: OK',   "Reject then resolve";
is $out[3], "4: OK\n", "Resolve then die";
is $out[4], "5: OK\n", "Reject then die";


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
