use strict;
use warnings;
use Promises 'deferred';
use Scalar::Util qw(weaken);
use Test::More 0.89;

my $count;
my $cb;

sub setup {
    $count = 0;
    $cb = sub { $count++ };
    my $d = deferred;
    my $p = $d->promise;
    for ( 1 .. 5 ) {
        $p = $p->then( $cb, $cb );
    }

    weaken $cb;
    return $d;
}

# Free resolve & reject on resolve()
my $d = setup();
ok $cb, "Weakened ref exists pre-resolve";

$d->resolve();

is $count, 5, "Resolve successful";
ok !$cb, "Weakened ref freed post-resolve";

# Free resolve & reject on reject()
$d = setup();
ok $cb, "Weakened ref exists pre-reject";

$d->reject();

is $count, 5, "Reject successful";
ok !$cb, "Weakened ref freed pos-reject";

done_testing;
