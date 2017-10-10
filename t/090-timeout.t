use strict;
use warnings;

use Test::More;
use Test::Requires 'IO::Async';

use lib 't/lib';
use Promises::Test;

use Promises 'deferred', 'collect';

subtest $_, \&test_me, $_ for qw/
    EV
    AnyEvent
    IO::Async
    AE
    Mojo
/;

sub test_me {
    plan tests => 6;

    my $backend = shift;

    $backend = Promises::Test::backend( $backend );

    my $p1 = deferred();
    my $p2 = $p1->timeout(1);
    my $p3 = $p1->then(sub { is_deeply \@_, [ 'gotcha' ], 'p3 resolved' });
    my $p4 = $p1->timeout(2)->then(sub { is $_[0] => 'gotcha' });

    collect($p3,$p4)->then(sub{ $backend->stop });

    ok $p1->is_in_progress;
    ok $p2->is_in_progress;

    $p2->catch(sub {
        is $_[0] => 'timeout', 'timed out';
        ok $p1->is_in_progress, "p1 still in progress";
        $p1->resolve('gotcha');
    });

    $backend->start;
}

done_testing;

