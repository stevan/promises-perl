package Promises;
our $AUTHORITY = 'cpan:YANICK';
$Promises::VERSION = '1.04';
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use Promises::Deferred;
our $Backend = 'Promises::Deferred';

our $WARN_ON_UNHANDLED_REJECT = 0;

use Sub::Exporter -setup => {

    collectors => [
        'backend' => \'_set_backend',
        'warn_on_unhandled_reject' => \'_set_warn_on_unhandled_reject',
    ],
    exports    => [qw[
        deferred resolved rejected
        collect collect_hash
    ]]
};

sub _set_warn_on_unhandled_reject {
    my( undef, $arg ) = @_;

    if( $WARN_ON_UNHANDLED_REJECT = $arg->[0] ) {
        # only brings the big guns if asked for

        *Promises::Deferred::DESTROY = sub {

            return unless $WARN_ON_UNHANDLED_REJECT;

            my $self = shift;

            return unless
                $self->is_rejected and not $self->{_reject_was_handled};

            require Data::Dumper;

            my $dump =
                Data::Dumper->new([$self->result])->Terse(1)->Dump;

            chomp $dump;
            $dump =~ s/\n\s*/ /g;

            warn "Promise's rejection ", $dump,
                " was not handled",
                ($self->{_caller} ? ( ' at ', join ' line ', @{$self->{_caller}} ) : ()) , "\n";
        };
    }
}

sub _set_backend {
    my ( undef, $arg ) = @_;
    my $backend = $arg->[0] or return;

    unless ( $backend =~ s/^\+// ) {
        $backend = 'Promises::Deferred::' . $backend;
    }
    require Module::Runtime;
    $Backend = Module::Runtime::use_module($backend) || return;
    return 1;

}

sub deferred(;&) {
    my $promise = $Backend->new;

    if ( my $code = shift ) {
        $promise->resolve;
        return $promise->then(sub{
            $code->($promise);
        });
    }

    return $promise;
}

sub resolved { deferred->resolve(@_) }
sub rejected { deferred->reject(@_)  }

sub collect_hash {
    collect(@_)->then( sub {
    map {
        my @values = @$_;
        die "'collect_hash' promise returned more than one value: [@{[ join ', ', @values ]} ]\n"
            if @values > 1;

        @values == 1 ? $values[0] : undef;
    } @_ })
}

sub collect {
    my @promises = @_;

    my $all_done = resolved();

    for my $p ( @promises ) {
        my @results;
        $all_done = $all_done->then( sub {
            @results = @_;
            return $p;
        } )->then(sub{ ( @results, [ @_ ] ) } );
    }

    return $all_done;
}

1;

__END__

=pod

=head1 NAME

Promises - An implementation of Promises in Perl

=head1 VERSION

version 1.04

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module is an implementation of the "Promise/A+" pattern for
asynchronous programming. Promises are meant to be a way to
better deal with the resulting callback spaghetti that can often
result in asynchronous programs.

=head1 FUTURE BACKWARDS COMPATIBILITY WARNING

The version of this module is being bumped up to 0.90 as the first
step towards 1.0 in which the goal is to have full Promises/A+ spec
compatibility. This is a departure to the previous goal of being
compatible with the Promises/A spec, this means that behavior may
change in subtle ways (we will attempt to document this completely
and clearly whenever possible).

It is B<HIGHLY> recommended that you test things very thoroughly
before upgrading to this version.

=head1 BACKWARDS COMPATIBILITY WARNING

In version up to and including 0.08 there was a bug in how
rejected promises were handled. According to the spec, a
rejected callback can:

=over

=item *

Rethrow the exception, in which case the next rejected handler
in the chain would be called, or

=item *

Handle the exception (by not C<die>ing), in which case the next
B<resolved> handler in the chain would be called.

=back

In previous versions of L<Promises>, this last step was handled incorrectly:
a rejected handler had no way of handling the exception.  Once a promise
was rejected, only rejected handlers in the chain would be called.

=head2 Relation to the various Perl event loops

This module is actually Event Loop agnostic, the SYNOPSIS above
uses L<AnyEvent::HTTP>, but that is just an example, it can work
with any of the existing event loops out on CPAN. Over the next
few releases I will try to add in documentation illustrating each
of the different event loops and how best to use Promises with
them.

=head2 Relation to the Promise/A spec

We are, with some differences, following the API spec called
"Promise/A" (and the clarification that is called "Promise/A+")
which was created by the Node.JS community. This is, for the most
part, the same API that is implemented in the latest jQuery and
in the YUI Deferred plug-in (though some purists argue that they
both go it wrong, google it if you care). We differ in some
respects to this spec, mostly because Perl idioms and best
practices are not the same as Javascript idioms and best
practices. However, the one important difference that should be
noted is that "Promise/A+" strongly suggests that the callbacks
given to C<then> should be run asynchronously (meaning in the
next turn of the event loop). We do not do this by default,
because doing so would bind us to a given event loop
implementation, which we very much want to avoid. However we
now allow you to specify an event loop "backend" when using
Promises, and assuming a Deferred backend has been written
it will provide this feature accordingly.

=head2 Using a Deferred backend

As mentioned above, the default Promises::Deferred class calls the
success or error C<then()> callback synchronously, because it isn't
tied to a particular event loop.  However, it is recommended that you
use the appropriate Deferred backend for whichever event loop you are
running.

Typically an application uses a single event loop, so all Promises
should use the same event-loop. Module implementers should just use the
Promises class directly:

    package MyClass;
    use Promises qw(deferred collect);

End users should specify which Deferred backend they wish to use. For
instance if you are using AnyEvent, you can do:

    use Promises backend => ['AnyEvent'];
    use MyClass;

The Promises returned by MyClass will automatically use whichever
event loop AnyEvent is using.

See:

=over 1

=item * L<Promises::Deferred::AE>

=item * L<Promises::Deferred::AnyEvent>

=item * L<Promises::Deferred::EV>

=item * L<Promises::Deferred::Mojo>

=item * L<Promises::Deferred::IO::Async>

=back

=head2 Relation to Promises/Futures in Scala

Scala has a notion of Promises and an associated idea of Futures
as well. The differences and similarities between this module
and the Promises found in Scalar are highlighted in depth in a
cookbook entry below.

=head2 Cookbook

=over 1

=item L<Promises::Cookbook::GentleIntro>

Read this first! This cookbook provides a step-by-step explanation
of how Promises work and how to use them.

=item L<Promises::Cookbook::SynopsisBreakdown>

This breaks down the example in the SYNOPSIS and walks through
much of the details of Promises and how they work.

=item L<Promises::Cookbook::TIMTOWTDI>

Promise are just one of many ways to do async programming, this
entry takes the Promises SYNOPSIS again and illustrates some
counter examples with various modules.

=item L<Promises::Cookbook::ChainingAndPipelining>

One of the key benefits of Promises is that it retains much of
the flow of a synchronous program, this entry illustrates that
and compares it with a synchronous (or blocking) version.

=item L<Promises::Cookbook::Recursion>

This entry explains how to keep the stack under control when
using Promises recursively.

=item L<Promises::Cookbook::ScalaFuturesComparison>

This entry takes some examples of Futures in the Scala language
and translates them into Promises. This entry also showcases
using Promises with L<Mojo::UserAgent>.

=back

=head1 EXPORTS

=over 4

=item C<deferred>

This just creates an instance of the L<Promises::Deferred> class
it is purely for convenience.

Can take a coderef, which will be dealt with as a C<then> argument.

    my $promise = deferred sub {
        ... do stuff ...

        return $something;
    };

    # equivalent to

    my $dummy = deferred;

    my $promise = $dummy->then(sub {
        ... do stuff ...

        return $something;
    });

    $dummy->resolve;

=item C<resolved( @values )>

Creates an instance of L<Promises::Deferred> resolved with
the provided C<@values>. Purely a shortcut for

    my $promise = deferred;
    $promise->resolve(@values);

=item C<rejected( @values )>

Creates an instance of L<Promises::Deferred> rejected with
the provided C<@values>. Purely a shortcut for

    my $promise = deferred;
    $promise->reject(@values);

=item C<collect( @promises )>

Accepts a list of L<Promises::Promise> objects and then
returns a L<Promises::Promise> object which will be called
once all the C<@promises> have completed (either as an error
or as a success).

The eventual result of the returned promise
object will be an array of all the results of each
of the C<@promises> in the order in which they where passed
to C<collect> originally, wrapped in arrayrefs, or the first error if
at least one of the promises fail.

If C<collect> is passed a value that is not a promise, it'll be wrapped
in an arrayref and passed through.

    my $p1 = deferred;
    my $p2 = deferred;
    $p1->resolve(1);
    $p2->resolve(2,3);

    collect(
        $p1,
        'not a promise',
        $p2,
    )->then(sub{
        print join ' : ', map { join ', ', @$_ } @_; # => "1 : not a promise : 2, 3"
    })

=item C<collect_hash( @promises )>

Like C<collect>, but flatten its returned arrayref into a single
hash-friendly list.

C<collect_hash> can be useful to a structured hash instead
of a long list of promise values.

For example,

  my $id = 12345;

  collect(
      fetch_it("http://rest.api.example.com/-/product/$id"),
      fetch_it("http://rest.api.example.com/-/product/suggestions?for_sku=$id"),
      fetch_it("http://rest.api.example.com/-/product/reviews?for_sku=$id"),
  )->then(
      sub {
          my ($product, $suggestions, $reviews) = @_;
          $cv->send({
              product     => $product,
              suggestions => $suggestions,
              reviews     => $reviews,
              id          => $id
          })
      },
      sub { $cv->croak( 'ERROR' ) }
  );

could be rewritten as

  my $id = 12345;

  collect_hash(
      id          => $id,
      product     => fetch_it("http://rest.api.example.com/-/product/$id"),
      suggestions => fetch_it("http://rest.api.example.com/-/product/suggestions?for_sku=$id"),
      reviews     => fetch_it("http://rest.api.example.com/-/product/reviews?for_sku=$id"),
  )->then(
      sub {
          my %results = @_;
          $cv->send(\%results);
      },
      sub { $cv->croak( 'ERROR' ) }
  );

Note that all promise values of the key/value pairs passed to C<collect_hash>
must return a scalar or nothing, as returning more than one value would
mess up the returned hash format. If a promise does return more than
one value, C<collect_hash> will consider it as having failed.

If you know that a
promise can return more than one value, you can do:

    my $collected = collect_hash(
        this => $promise_returning_scalar,
        that => $promise_returning_list->then(sub{ [ @_ ] } ),
    );

=back

=head1 SEE ALSO

=head2 Promises in General

=over 4

=item L<You're Missing the Point of Promises|http://domenic.me/2012/10/14/youre-missing-the-point-of-promises/>

=item L<Systems Programming at Twitter|http://monkey.org/~marius/talks/twittersystems/>

=item L<SIP-14 - Futures and Promises|http://docs.scala-lang.org/sips/pending/futures-promises.html>

=item L<Promises/A+ spec|http://promises-aplus.github.io/promises-spec/>

=item L<Promises/A spec|http://wiki.commonjs.org/wiki/Promises/A>

=back

=head2 Perl Alternatives

=over

=item L<Future>

=item L<Mojo::Promise>

Part of the L<Mojolicious> package.

=item L<Promise::ES6>

=item L<Promise::Tiny>

=item L<AnyEvent::XSPromises>

=item L<Promise::XS>

=back

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017, 2014, 2012 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
