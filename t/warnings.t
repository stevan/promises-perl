use strict;
use warnings;

use Test::More;
use Test::Warn;

use Promises qw(deferred), 'warn_on_unhandled_reject' => [1];

warning_like {
    my $d = deferred();
    $d->then(sub {die "boo"})->then(sub { 'stuff' });
    $d->resolve;
} qr!Promise's rejection.*boo.*at t/warnings.t line 11!s, "catch a die";

warning_like {
    my $d = deferred();
    $d->then(sub { "boo"})->then(sub { 'stuff' });
    $d->reject(1,2,3);
} qr!Promise's rejection.*line 17!s, "catch regular reject";

warning_like {
    my $d = deferred();
    $d->then(sub { "boo"})->then(sub { 'stuff' });
    $d->reject(1,2,3);
} qr!Promise's rejection \[ 1, 2, 3 \].*line 23!s, "nicely formatted single-line rejection dump";


done_testing;
