use strict;
use warnings;

use Test::More;
use Test::Warn;

use Promises qw(deferred);

warning_like {
    my $d = deferred();
    $d->then(sub {die "boo"})->then(sub { 'stuff' });
    # Simulate run-time requiring a package use-ing warn_on_unhandled_reject
    Promises->import('warn_on_unhandled_reject' => [1]);
    $d->resolve;
} qr!Promise's rejection.*boo.*at t/late-warning.t line 11!s, "catch a die";


done_testing;
