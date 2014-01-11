#!perl

use strict;
use warnings;

use Test::More;

use Mojo::IOLoop;;

use Promises backend => ['Mojo'], 'deferred';

my $run = 0;

my $d = deferred;
$d->then( sub { $run++ });
$d->resolve;

is($run, 0, '... not run synchronously');

Mojo::IOLoop->one_tick;

is($run, 1, '... run asynchronously');

done_testing;

