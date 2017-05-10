package Promises::Attribute;
# ABSTRACT: Turns functions into promises

use strict;
use warnings;

use Sub::Attribute;

use Promises qw/ collect /;

sub Promise :ATTR_SUB {
    my( undef, $symbol, $referent ) = @_;

    warn $symbol;
    $$symbol = sub { 
        warn join " : ", @_;
        collect( @_ )->then( sub { $referent->(map { @$_ } @_) } );
    };
}

1;

__END__

=head1 SYNOPSIS

    use Promises 'deferred';
    use parent 'Promises::Attribute';

    sub shall_concat :Promise {
        join ' ', @_;
    }


    my @promises = map { deferred } 1..2;

    my @results = (
        shall_concat( @promises ),
        shall_concat( 'that is', $promises[1] ),
        shall_concat( 'this is', 'straight up' ),
    );

    say "all results are promises";

    $_->then(sub { say @_ } ) for @results;
    # prints 'this is straight up'

    say "two results are still waiting...";

    $promises[1]->resolve( 'delayed' );
    # prints 'this is delayed'

    say "only one left...";

    $promises[0]->resolve( 'finally the last one, that was' );
    # prints 'finally the last one, that was delayed'

=head1 DESCRIPTION

Any function tagged with the C<:Promise> will be turned into a promise, so you can do

    sub add :Promise { $_[0] + $_[1] }

    add( 1,2 )->then(sub { say "the result is ", @_ } );

Additionally, if any of the arguments to the functions are promises themselves,
the function call will wait until those promises are fulfilled before running.

    my $number = deferred;

    add( 1, $number )->then(sub { say "result: ", @_ } );

    # $number is not fulfilled yet, nothing is printed

    $number->resolve(47);
    # prints 'result: 48'

Note: to use the attributes, you have to do C<use parent 'Promises::Attribute';>,
and not C<use Promises::Attribute;> in the target namespace.
