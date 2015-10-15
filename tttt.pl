use strict;
use warnings;
use v5.16;

use AnyEvent;
use Promises backend => ['AnyEvent'];
use Promises qw(deferred);


my $cv = AnyEvent->condvar;
my $d = deferred();
#$d->then(sub {die "boo"})->then(sub {print STDERR "wtf\n"; $cv->send }, sub { print STDERR "rejected\n"; });
$d->then(sub {die "boo"})->then(sub {print STDERR "wtf\n"; $cv->send });
$d->resolve("xxx");

$cv->recv;
