package Promises;

# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use Promises::Deferred;
our $Backend = 'Promises::Deferred';

use Sub::Exporter -setup => {
    collectors => [ 'backend' => \'_set_backend' ],
    exports    => [qw[ deferred collect resolved rejected ]]
};

sub _set_backend {
    my ( $class, $arg ) = @_;
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

sub collect {
    my @promises = @_;

    my $all_done  = $Backend->new;
    my $results   = [];
    my $remaining = scalar @promises;
    foreach my $i ( 0 .. $#promises ) {
        my $p = $promises[$i];
        $p->then(
            sub {
                $results->[$i] = [@_];
                $remaining--;
                if (   $remaining == 0
                    && $all_done->status ne $all_done->REJECTED )
                {
                    $all_done->resolve(@$results);
                }
            },
            sub { $all_done->reject(@_) },
        );
    }

    $all_done->resolve(@$results)
        if $remaining == 0 and $all_done->is_in_progress;

    $all_done->promise;
}

1;

__END__

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

The only export for this module is the C<collect> function, which
accepts an array of L<Promises::Promise> objects and then
returns a L<Promises::Promise> object which will be called
once all the C<@promises> have completed (either as an error
or as a success). The eventual result of the returned promise
object will be an array of all the results (or errors) of each
of the C<@promises> in the order in which they where passed
to C<collect> originally.

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







