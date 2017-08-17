use strict;
use warnings;

use Test::More;
use Test::Requires 'IO::Async';

use IO::Async::Loop;

use Promises backend => ['IO::Async'], 'deferred';

my $loop = IO::Async::Loop->new;

my $run = 0;

my $d = deferred;
$d->then( sub { $run++ });
$d->resolve;

ok !$run,'... not run synchronously';

$loop->loop_once(1);

ok $run, '... run asynchronously';

done_testing;

