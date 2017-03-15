#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Requires 'AnyEvent';

use lib 't/lib';

use AsyncUtil qw/ delay_me /;

use Promises qw/ deferred /;

my $cv = AE::cv;

my $promise = deferred {
    my $d = shift;

    delay_me(2)->then(sub{ $d->resolve; $cv->send });
};

is $promise->status => 'in progress';

$cv->recv;

is $promise->status => 'resolved';
