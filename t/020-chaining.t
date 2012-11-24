#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use AnyEvent;
use AsyncUtil qw[ perform_asyncly ];

BEGIN {
    use_ok('Promises');
}

my $cv = AnyEvent->condvar;

perform_asyncly(
    'The quick brown fox jumped over the lazy dog',
    sub { split /\s/ => shift }
)->then(
    sub {
        my @words = @_;
        perform_asyncly(
            \@words,
            sub { map { lc $_ } @{ $_[0] } }
        );
    }
)->then(
    sub {
        my @lowercased = @_;
        perform_asyncly(
            \@lowercased,
            sub { sort { $a cmp $b } @{ $_[0] } }
        )
    }
)->then(
    sub {
        my @sorted = @_;
        perform_asyncly(
            \@sorted,
            sub { my %seen; grep { not $seen{$_}++ } @{ $_[0] } }
        )
    }
)->then(
    sub { $cv->send( @_ ) },
    sub { $cv->croak( 'ERROR' ) }
);

is_deeply(
    [ $cv->recv ],
    [ qw[ brown dog fox jumped lazy over quick the  ] ],
    '... got the expected values back'
);

done_testing;