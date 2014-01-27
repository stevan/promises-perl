#!perl

use strict;
use warnings;

use lib 't/lib';
use Promises qw(deferred);
use AE;
use Test::More;

BEGIN {
    use_ok('Promises');
}

my $cv = AE::cv;
deferred->resolve('foo')->then($cv);
is $cv->recv, 'foo', 'Resolve callable';

$cv = AE::cv;
deferred->reject('foo')->then( undef, $cv );
is $cv->recv, 'foo', 'Reject callable';

$cv = AE::cv;
deferred->resolve('foo')->finally($cv);
is $cv->recv, 'foo', 'Resolve finally callable';

$cv = AE::cv;
deferred->reject('foo')->finally($cv);
is $cv->recv, 'foo', 'Reject finally callable';

$cv = AE::cv;
deferred->resolve('foo')->done($cv);
is $cv->recv, 'foo', 'Resolve done callable';

$cv = AE::cv;
deferred->reject('foo')->done( undef, $cv );
is $cv->recv, 'foo', 'Reject done callable';

done_testing;

