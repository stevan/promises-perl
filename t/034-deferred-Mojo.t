#!perl

use strict;
use warnings;

use lib 't/lib';
use NoEV;
use Test::More;

BEGIN {
    if (!eval { require Mojo::IOLoop; Mojo::IOLoop->import; 1 }) {
        plan skip_all => "Mojo::IOLoop is required for this test";
    }
}

use Promises backend => ['Mojo'], 'deferred';

my $run = 0;

my $d = deferred;
$d->then( sub { $run++ });
$d->resolve;

is($run, 0, '... not run synchronously');

Mojo::IOLoop->one_tick;

is($run, 1, '... run asynchronously');

done_testing;

