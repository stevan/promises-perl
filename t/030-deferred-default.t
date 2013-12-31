#!perl

use strict;
use warnings;

use Test::More;

use Promises 'deferred';

my $run = 0;

my $d = deferred;
$d->then( sub { $run++ });
$d->resolve;

is($run, 1, '... run synchronously');

done_testing;

