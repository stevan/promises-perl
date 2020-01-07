# Promises for Perl

[![CPAN version](https://badge.fury.io/pl/Promises.svg)](https://metacpan.org/pod/Promises)

This module is an implementation of the "Promise/A+" pattern for
asynchronous programming. Promises are meant to be a way to
better deal with the resulting callback spaghetti that can often
result in asynchronous programs.

## SYNOPSIS

```perl
use AnyEvent::HTTP;
use JSON::XS qw[ decode_json ];
use Promises qw[ collect deferred ];

sub fetch_it {
    my ($uri) = @_;
    my $d = deferred;
    http_get $uri => sub {
        my ($body, $headers) = @_;
        $headers->{Status} == 200
            ? $d->resolve( decode_json( $body ) )
            : $d->reject( $body )
    };
    $d->promise;
}

my $cv = AnyEvent->condvar;

collect(
    fetch_it('http://rest.api.example.com/-/product/12345'),
    fetch_it('http://rest.api.example.com/-/product/suggestions?for_sku=12345'),
    fetch_it('http://rest.api.example.com/-/product/reviews?for_sku=12345'),
)->then(
    sub {
        my ($product, $suggestions, $reviews) = @_;
        $cv->send({
            product     => $product,
            suggestions => $suggestions,
            reviews     => $reviews,
        })
    },
    sub { $cv->croak( 'ERROR' ) }
);

my $all_product_info = $cv->recv;
```

## INSTALLATION

To install this module from its CPAN tarball, type the following:

   perl Makefile.PL
   make
   make test
   make install


If you cloned the github repo, the branch `releases` has the 
same code than the one living in CPAN, so the same `Makefile` 
dance will work. The` master` branch, however, needs to be built using
Dist::Zilla:

    dzil install

Be warned that the Dist::Zilla configuration is fine-tuned 
to my needs, so the dependency
list to get it running is ludicrously huge. If you want a quick
and dirty install, you can also do:

    git checkout releases -- Makefile.PL
    perl Makefile.PL
    make test
    make install

## DEPENDENCIES

This module requires these other modules and libraries:

    Test::More

This module optionally requires these other modules and libraries in
order to support some specific features.

    AnyEvent
    Mojo::IOLoop
    EV
    IO::Async

## SEE ALSO

- http://promises-aplus.github.io/promises-spec/

## COPYRIGHT AND LICENCE

Copyright (C) 2012-2014 Infinity Interactive, Inc.

http://www.iinteractive.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

