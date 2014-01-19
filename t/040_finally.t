#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use AnyEvent;
use AsyncUtil qw[ delay_me delay_me_error ];

BEGIN {
    use_ok('Promises');
}

my @vals = ( 'val_1', 'val_2' );

my $cv = AnyEvent->condvar;
my @out;

# Finally executes normally
test(
    "Resolve - Finally - Resolve",
    sub {
        delay_me(0.1)    #
            ->then( sub    {@vals} )               #
            ->finally( sub { out('Finally') } )    #
            ->then( \&got_vals );
    },
    [ 'Finally', 'Got vals' ]
);

test(
    "Reject - Finally - Reject",
    sub {
        delay_me_error(0.1)                        #
            ->catch( sub   {@vals} )               #
            ->finally( sub { out('Finally') } )    #
            ->catch( \&got_vals );
    },
    [ 'Finally', 'Got vals' ]
);

test(
    "Resolve dies - Finally - Reject",
    sub {
        delay_me(0.1)                              #
            ->then( sub    { die "Died\n" } )      #
            ->finally( sub { out('Finally') } )    #
            ->catch( \&got_error );
    },
    [ 'Finally', 'Got error' ]
);

# Finally throws error
test(
    "Resolve - Finally dies - Resolve",
    sub {
        delay_me(0.1)                              #
            ->then( sub {@vals} )                              #
            ->finally( sub { out('Finally'); die('Foo') } )    #
            ->then( \&got_vals );
    },
    [ 'Finally', 'Got vals' ]
);

test(
    "Reject - Finally dies - Reject",
    sub {
        delay_me_error(0.1)                                    #
            ->catch( sub {@vals} )                             #
            ->finally( sub { out('Finally'); die('Foo') } )    #
            ->catch( \&got_vals );
    },
    [ 'Finally', 'Got vals' ]
);

test(
    "Resolve dies - Finally dies - Reject",
    sub {
        delay_me(0.1)                                          #
            ->then( sub { die "Died\n" } )                     #
            ->finally( sub { out('Finally'); die('Foo') } )    #
            ->catch( \&got_error );
    },
    [ 'Finally', 'Got error' ]
);

# Finally returns resolved promise
test(
    "Resolve - Finally resolves - Resolve",
    sub {
        delay_me(0.1)                                          #
            ->then( sub {@vals} )                              #
            ->finally(
            sub {
                out('Finally');
                delay_me(0.1)->then( sub { out('Resolved') } );
            }
            )                                                  #
            ->then( \&got_vals );
    },
    [ 'Finally', 'Resolved', 'Got vals' ]
);

test(
    "Reject - Finally resolves - Reject",
    sub {
        delay_me_error(0.1)                                    #
            ->catch( sub {@vals} )                             #
            ->finally(
            sub {
                out('Finally');
                delay_me(0.1)->then( sub { out('Resolved') } );
            }
            )                                                  #
            ->catch( \&got_vals );
    },
    [ 'Finally', 'Resolved', 'Got vals' ]
);

test(
    "Resolve dies - Finally resolves - Reject",
    sub {
        delay_me(0.1)                                          #
            ->then( sub { die "Died\n" } )                     #
            ->finally(
            sub {
                out('Finally');
                delay_me(0.1)->then( sub { out('Resolved') } );
            }
            )                                                  #
            ->catch( \&got_error );
    },
    [ 'Finally', 'Resolved', 'Got error' ]
);

# Finally returns rejected promise
test(
    "Resolve - Finally rejects - Resolve",
    sub {
        delay_me(0.1)                                          #
            ->then( sub {@vals} )                              #
            ->finally(
            sub {
                out('Finally');
                delay_me_error(0.1)->catch( sub { out('Rejected') } );
            }
            )                                                  #
            ->then( \&got_vals,sub{"NO"} );
    },
    [ 'Finally', 'Rejected', 'Got vals' ]
);

test(
    "Reject - Finally rejects - Reject",
    sub {
        delay_me_error(0.1)                                    #
            ->catch( sub {@vals} )                             #
            ->finally(
            sub {
                out('Finally');
                delay_me_error(0.1)->catch( sub { out('Rejected') } );
            }
            )                                                  #
            ->catch( \&got_vals );
    },
    [ 'Finally', 'Rejected', 'Got vals' ]
);

test(
    "Resolve dies - Finally rejects - Reject",
    sub {
        delay_me(0.1)                                          #
            ->then( sub { die "Died\n" } )                     #
            ->finally(
            sub {
                out('Finally');
                delay_me_error(0.1)->catch( sub { out('Rejected') } );
            }
            )                                                  #
            ->catch( \&got_error );
    },
    [ 'Finally', 'Rejected', 'Got error' ]
);

#===================================
sub test {
#===================================
    my ( $name, $cb, $expect ) = @_;
    @out = ();
    my $cv = AE::cv;

    $cb->()->then( sub { $cv->send }, sub { $cv->send } );
    $cv->recv;

#    diag "";
#    diag "$name";
#    diag "Expect: @$expect";
#    diag "Got: @out";
    no warnings 'uninitialized';
    return fail $name unless @out == @$expect;
    for ( 0 .. @out ) {
        return fail $name unless $out[$_] eq $expect->[$_];
    }
    pass $name;

}

sub got_vals {
    no warnings 'uninitialized';
    $_[0] eq $vals[0] && $_[1] eq $vals[1]
        ? out('Got vals')
        : out('No vals');
}

sub got_error {
    no warnings 'uninitialized';
    $_[0] eq "Died\n"
        ? out('Got error')
        : out('No error');
}

sub out {
    push @out, shift();
}

done_testing;
