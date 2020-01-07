#!perl

use strict;
use warnings;

use Test::More;
use Test::Requires 'AE';

use AE;

use Promises backend => ['AE'], 'deferred';

my $run = 0;

my $d = deferred;
$d->then( sub { $run++ });
$d->resolve;

is($run, 0, '... not run synchronously');

my $cv = AE::cv;
my $w  = AE::timer( 0.01, 0, sub{ $cv->send } );

$cv->recv;

is($run, 1, '... run asynchronously');

done_testing;

