# Promises for Perl

This module is an implementation of the "Promise/A+" pattern for
asynchronous programming. Promises are meant to be a way to
better deal with the resulting callback spaghetti that can often
result in asynchronous programs.

## SYNOPSIS

```
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

To install this module type the following:

   perl Makefile.PL
   make
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

## SEE ALSO

- http://promises-aplus.github.io/promises-spec/

## COPYRIGHT AND LICENCE

Copyright (C) 2012-2014 Infinity Interactive, Inc.

http://www.iinteractive.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

