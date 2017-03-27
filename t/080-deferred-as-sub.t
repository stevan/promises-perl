#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Requires 'AnyEvent';

use lib 't/lib';

use AsyncUtil qw/ delay_me /;

use Promises qw/ deferred /;

my $cv = AE::cv;

my $promise = deferred {
    delay_me(2)->then(sub{ $cv->send });
};

my $bad_promise = deferred {
    delay_me(2)->then(sub{ die "oops"; });
};

is $promise->status     => 'in progress';
is $bad_promise->status => 'in progress';

$cv->recv;

is $promise->status => 'resolved';

is $bad_promise->status => 'rejected';
