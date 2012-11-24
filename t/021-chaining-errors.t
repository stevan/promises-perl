#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Promises');
}

# make sure chained promises bubble
# to the right handlers

Promises::Deferred->new->resolve("foo")->then(
    sub {
        my $result = shift;
        is($result, "foo", "... resolved foo");
        return Promises::Deferred->new->reject("bar")->promise;
    }
)->then(
    sub { fail("This should never be called") },
    sub {
        my $result = shift;
        is($result, "bar", "... rejected bar");
    }
);

Promises::Deferred->new->resolve("foo")->then(
    sub {
        my $result = shift;
        is($result, "foo", "... resolved foo");
        return Promises::Deferred->new->reject("bar")->promise;
    }
)->then(
    sub { fail("This should never be called") },
)->then(
    sub { fail("This should never be called") },
)->then(
    sub { fail("This should never be called") },
)->then(
    sub { fail("This should never be called") },
    sub {
        my $result = shift;
        is($result, "bar", "... rejected bar (at arbitrary depth)");
    }
);

# check the chaining of literal values as well ...

Promises::Deferred->new->resolve("foo")->then(
    sub {
        my $result = shift;
        is($result, "foo", "... resolved foo");
        "bar";
    }
)->then(
    sub {
        my $result = shift;
        is($result, "bar", "... chained-resolve bar");
    }
);

Promises::Deferred->new->reject("bar")->then(
    sub { fail("This should never be called") },
    sub {
        my $result = shift;
        is($result, "bar", "... rejectd bar");
        "foo";
    }
)->then(
    sub { fail("This should never be called") },
    sub {
        my $result = shift;
        is($result, "foo", "... chained-reject foo");
    }
);

done_testing;
