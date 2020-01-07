#!perl

use strict;
use warnings;

use Test::More;
use Test::Requires 'AnyEvent';

use AnyEvent;

use Promises backend => ['AnyEvent'], 'deferred';

my $run = 0;

my $d = deferred;
$d->then( sub { $run++ });
$d->resolve;

is($run, 0, '... not run synchronously');

my $cv = AnyEvent->condvar;
my $w  = AnyEvent->timer( after => 0.01, cb => sub{ $cv->send } );

$cv->recv;

is($run, 1, '... run asynchronously');

done_testing;

