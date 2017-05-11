#!perl

use strict;
use warnings;

use Test::More tests => 3;

use Promises qw/ resolved rejected collect /;

my $resolved = resolved( 1..3 )->then(
    sub { is_deeply \@_, [1..3], 'resolved' },
    sub { fail 'resolved' },
);

my $rejected = rejected( 4..6 )->then(
    sub { fail 'rejected' },
    sub { is_deeply \@_, [4..6], 'rejected' },
);

collect( $resolved, $rejected )->finally(sub{
    pass 'all done';
});

done_testing;
