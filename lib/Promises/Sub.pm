package Promises::Sub;
# ABSTRACT: Turns functions into promises

use strict;
use warnings;

use Sub::Attribute;
use Carp;

use Promises qw/ collect flat_collect /;

use parent 'Exporter';

our @EXPORT_OK = qw/ defer /;

sub defer(&) {
    my $coderef = shift;

    return sub {
        flat_collect( @_ )->then( $coderef ); 
    }

}

sub Defer :ATTR_SUB {
    my( undef, $symbol, $referent ) = @_;

    croak "can't use attribute :Defer on an anonynous sub, use 'defer' instead"
        unless $symbol;

    no warnings 'redefine';
    $$symbol = defer { $referent->(@_) };
}


1;

__END__

=head1 SYNOPSIS

    use Promises 'deferred';
    use parent 'Promises::Sub';

    sub shall_concat :Defer {
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

Any function tagged with the C<:Defer> will be turned into a promise, so you can do

    sub add :Defer { $_[0] + $_[1] }

    add( 1,2 )->then(sub { say "the result is ", @_ } );

Additionally, if any of the arguments to the functions are promises themselves,
the function call will wait until those promises are fulfilled before running.

    my $number = deferred;

    add( 1, $number )->then(sub { say "result: ", @_ } );

    # $number is not fulfilled yet, nothing is printed

    $number->resolve(47);
    # prints 'result: 48'

Bear in mind that to use the C<:Defer> attribute, you have to 
do C<use parent 'Promises::Sub';>,
and not C<use Promises::Sub;> in the target namespace.

=head2 Anonymous functions

The C<:Defer> attribute won't work for anonymous functions and will throw
an exception. For those, you can
export the function C<defer>, which will wrap any coderef the same way that
C<:Defer> does.

    use Promises::Sub qw/ defer /;

    my $promised_sub = defer sub {
        join ' ', @_;
    };

    my $p1 = deferred;

    $promised_sub->( 'hello', $p1 )->then( sub {
        say shift;
    } );

    # prints nothing

    $p1->resolve('world');
    # => prints 'hello world'
