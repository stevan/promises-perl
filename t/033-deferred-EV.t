#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    if (!eval { require EV; EV->import; 1 }) {
        plan skip_all => "EV is required for this test";
    }
}

use Promises backend => ['EV'], 'deferred';

my $run = 0;

my $d = deferred;
$d->then( sub { $run++ });
$d->resolve;

is($run, 0, '... not run synchronously');

EV::loop;

is($run, 1, '... run asynchronously');

done_testing;

