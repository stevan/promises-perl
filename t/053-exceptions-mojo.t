#!perl

use strict;
use warnings;

use lib 't/lib';
use NoEV;
use Test::More;
use Test::Fatal;

use Test::Requires 'Mojo::IOLoop';

use Promises qw/deferred/, backend => ["Mojo"];

my @out;

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

        Mojo::IOLoop->timer( 0.3, sub { Mojo::IOLoop->stop } );
        Mojo::IOLoop->start;
    },
    undef,
    "Exception in Mojo done is swallowed"
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
    Mojo::IOLoop->timer( 0, sub { $d->resolve('OK') } );
    $d->promise;
}

done_testing;
