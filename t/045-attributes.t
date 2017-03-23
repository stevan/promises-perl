use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

use Promises 'deferred';
use parent 'Promises::Sub';

use Promises::Sub qw/ defer /;


sub shall_concat :Defer {
    join ' ', @_;
}

my @promises = map { deferred } 1..2;

my @results = (
    shall_concat( @promises ),
    shall_concat( 'that is', $promises[1] ),
    shall_concat( 'this is', 'straight up' ),
);

my @test_results;
$_->then(sub { push @test_results, @_ } ) for @results;

is_deeply \@test_results, [ 'this is straight up' ];

$promises[1]->resolve( 'delayed' );

$promises[0]->resolve( 'finally the last one, that was' );

is_deeply \@test_results, [ 
    'this is straight up',
    'that is delayed',
    'finally the last one, that was delayed',
];

subtest defer => sub {
    my $promised_sub = defer sub {
        join ' ', @_;
    };

    my $p1 = deferred;

    my @result;
    $promised_sub->( 'hello', $p1 )->then( sub {
        push @result, shift;
    } );

    is_deeply \@result, [], 'nothing yet';

    $p1->resolve('world');
    is_deeply \@result, ['hello world'], 'resolved';
};
