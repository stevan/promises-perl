#!perl

use strict;
use warnings;

use Test::More;

use EV;

use Promises backend => ['EV'], 'deferred';

my $run = 0;

my $d = deferred;
$d->then( sub { $run++ });
$d->resolve;

is($run, 0, '... not run synchronously');

EV::loop;

is($run, 1, '... run asynchronously');

done_testing;

