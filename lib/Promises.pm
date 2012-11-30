package Promises;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use Promises::Deferred;

use Sub::Exporter -setup => {
    exports => [qw[ when ]]
};

sub when {
    my @promises = @_;

    my $all_done  = Promises::Deferred->new;
    my $results   = [];
    my $remaining = scalar @promises;

    foreach my $i ( 0 .. $#promises ) {
        my $p = $promises[$i];
        $p->then(
            sub {
                $results->[$i] = [ @_ ];
                $remaining--;
                if ( $remaining == 0 && $all_done->status ne $all_done->REJECTED ) {
                    $all_done->resolve( @$results );
                }
            },
            sub { $all_done->reject }
        );
    }

    $all_done->resolve( @$results ) if $remaining == 0;

    $all_done->promise;
}

1;

__END__

=head1 SYNOPSIS

  use AnyEvent::HTTP;
  use JSON::XS qw[ decode_json ];
  use Promises qw[ when ];

  sub fetch_it {
      my ($uri) = @_;
      my $d = Promises::Deferred->new;
      http_get $uri => sub {
          my ($body, $headers) = @_;
          $headers->{Status} == 200
              ? $d->resolve( decode_json( $body ) )
              : $d->reject( $body )
      };
      $d->promise;
  }

  my $cv = AnyEvent->condvar;

  when(
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

This module is an implementation of the "Promise" pattern for
asynchronous programming. Promises are meant to be a way to
better deal with the resulting callback spaghetti that can often
result in asynchronous programs.

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
next turn of the event loop). We do not do this because doing
so would bind us to a given event loop implementation, which
we very much want to avoid.

=head2 Relation to Futures in Scala

In Scala, Promises are called Futures, they are very similar
in concept, but very different in practice. This module makes
no attempt to be like Scala futures, so don't even bother
comparing them. That said, I might at some point steal some
of the nicer Future combinators that Scala provides.

=head2 Breaking down the SYNOPSIS

The example in the synopsis actually demonstrates a number
of the features of this module, this section will break down
each part and explain them in order.

  sub fetch_it {
      my ($uri) = @_;
      my $d = Promises::Deferred->new;
      http_get $uri => sub {
          my ($body, $headers) = @_;
          $headers->{Status} == 200
              ? $d->resolve( decode_json( $body ) )
              : $d->reject( $body )
      };
      $d->promise;
  }

First is the C<fetch_it> function, the pattern within this function
is the typical way in which you might wrap an async function call
of some kind. The first thing we do it to create an instance of
L<Promises::Deferred>, this is the class which does the majority
of the work or managing callbacks and the like. Then within the
callback for our async function, we will call methods on the
L<Promises::Deferred> instance. In the case we first check the
response headers to see if the request was a success, if so, then
we call the C<resolve> method and pass the decoded JSON to it.
If the request failed, we then call the C<reject> method and
send back the data from the body. Finally we call the C<promise>
method and return the promise 'handle' for this deferred instance.

At this point out asynchronous operation will typically be in
progress, but control has been returned to the rest of our
program. Now, before we dive into the rest of the example, lets
take a quick detour to look at what promises do. Take the following
code for example:

  my $p = fetch_it('http://rest.api.example.com/-/user/bob@example.com');

At this point, our async operation is running, but we have not yet
given it anything to do when the callback is fired. We will get to
that shortly, but first lets look at what information we can get
from the promise.

  $p->status;

Calling the C<status> method will return a string representing the
status of the promise. This will be either I<in progress>, I<resolved>,
I<resolving> (meaning it is in the process of resolving), I<rejected>
or I<rejecting> (meaning it is in the process of rejecting).
(NOTE: these are also constants on the L<Promises::Deferred> class,
C<IN_PROGRESS>, C<RESOLVED>, C<REJECTED>, etc., but they are also
available as predicate methods in both the L<Promises::Deferred> class
and proxied in the L<Promises::Promise> class). At this point, this
method call is likely to return I<in progress>. Next is the C<result>
method:

  $p->result;

which will give us back the values that are passed to either C<resolve>
or C<reject> on the associated L<Promises::Deferred> instance.

Now, one thing to keep in mind before we go any further is that our
promise is really just a thin proxy over the associated L<Promises::Deferred>
instance, it stores no state itself, and when these methods are called on
it, it simply forwards the call to the associated L<Promises::Deferred>
instance (which, as I said before, is where all the work is done).

So, now, lets actually do something with this promise. So as I said above
the goal of the Promise pattern is to reduce the callback spaghetti that
is often created with writing async code. This does not mean that we have
no callbacks at all, we still need to have some kind of callback, the
difference is all in how those callbacks are managed and how we can more
easily go about providing some level of sequencing and control.

That all said, lets register a callback with our promise.

  $p->then(
      sub {
          my ($user) = @_;
          do_something_with_a_user( $user );
      },
      sub {
          my ($err) = @_;
          warn "An error was received : $err";
      }
  );

As you can see, we use the C<then> method (again, keep in mind this is
just proxying to the associated L<Promises::Deferred> instance) and
passed it two callbacks, the first is for the success case (if C<resolve>
has been called on our associated L<Promises::Deferred> instance) and
the second is the error case (if C<reject> has been called on our
associated L<Promises::Deferred> instance). Both of these callbacks will
receive the arguments that were passed to C<resolve> or C<reject> as
their only arguments, as you might have guessed, these values are the
same values you would get if you called C<result> on the promise
(assuming the async operation was completed).

It should be noted that the error callback is optional. If it is not
specified then errors will be silently eaten (similar to a C<try> block
that has not C<catch>). If there is a chain of promises however, the
error will continue to bubble to the last promise in the chain and
if there is an error callback there, it will be called. This allows
you to concentrate error handling in the places where it makes the most
sense, and ignore it where it doesn't make sense. As I alluded to above,
this is very similar to nested C<try/catch> blocks.

And really, thats all there is to it. You can continue to call C<then>
on a promise and it will continue to accumulate callbacks, which will
be executed in in FIFO order once a call is made to either C<resolve>
or C<reject> on the associated L<Promises::Deferred> instance. And in
fact, it will even work after the async operation is complete. Meaning
that if you call C<then> and the async operation is already completed,
your callback will be executed immediately.

So, now lets get back to our original example. I will briefly explain
my usage of the L<AnyEvent> C<condvar>, but I encourage you to review
the docs for L<AnyEvent> yourself if my explanation is not enough.

So, the idea behind my usage of the C<condvar> is to provide a
merge-point in my code at which point I want all the asynchronous
operations to converge, after which I can resume normal synchronous
programming (if I so choose). It provides a kind of a transaction
wrapper if you will, around my async operations. So, first step is
to actually create that C<condvar>.

  my $cv = AnyEvent->condvar;

Next, we jump back into the land of Promises. Now I am breaking apart
the calling of C<when> and the subsequent chained C<then> call here
to help keep things in digestible chunks, but also to illustrate that
C<when> just returns a promise (as you might have guessed anyway).

  my $p = when(
      fetch_it('http://rest.api.example.com/-/product/12345'),
      fetch_it('http://rest.api.example.com/-/product/suggestions?for_sku=12345'),
      fetch_it('http://rest.api.example.com/-/product/reviews?for_sku=12345'),
  );

So, what is going on here is that we want to be able to run multiple
async operations in parallel, but we need to wait for all of them to
complete before we can move on, and C<when> gives us that ability.
As we know from above, C<fetch_it> is returning a promise, so obviously
C<when> takes an array of promises as its parameters. As we said before
C<when> also returns a promise, which is just a handle on a
C<Promises::Deferred> instance it created to watch and handle the
multiple promises you passed it. Okay, so now lets move onto adding
callbacks to our promise that C<when> returned to us.

  $p->then(
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

So, you will notice that, as before, we provide a success and an error
callback, but you might notice one slight difference in the success
callback. It is actually being passed multiple arguments, these are
the results of the three C<fetch_it> calls passed into C<when>, and yes,
they are passed to the callback in the same order you passed them into
C<when>. So from here we jump back into the world of C<condvars>, and
we call the C<send> method and pass it our newly assembled set of
collected product info. As I said above, C<condvars> are a way of
wrapping your async operations into a transaction like block, when
code execution encounters a C<recv>, such as in our next line of code:

  my $all_product_info = $cv->recv;

the event loop will block until a corresponding C<send> is called on
the C<condvar>. While you are not required to pass arguments to C<send>
it will accept them and the will in turn be the return values of
the corresponding C<recv>, which makes for an incredibly convenient
means of passing data around your asynchronous program.

It is also worth noting the usage of the C<croak> method on the
C<condvar> in the error callback. This is the preferred way of
dealing with exceptions in L<AnyEvent> because it will actually
cause the exception to be thrown from C<recv> and not somewhere
deep within a callback.

And that is all of it, once C<recv> returns, our program will go
back to normal synchronous operation and we can do whatever it is
we like with C<$all_product_info>.

=head2 TIMTOWTDI

So, like I said before, Promises are a means by which you can more
effectively manage your async operations and avoid callback spaghetti.
But of course this is Perl and therefore there is always another way
to do it. In this section I am going to show a few examples of other
ways you could accomplish the same thing.

NOTE: Please note that I am specifically illustrating ways to do
this which I feel are inferior or less elegant then Promises. This
is not meant to be a slight on the API to L<AnyEvent::HTTP> at all,
I am simply using it because I used it in my original example. These
same issues/patterns could be illustrated with any async library
that takes callbacks in this way.

CAVEAT: I am sure there are other ways to do these things and do them
more effectively, and I am fully willing to admit my ignorance here.
I welcome any patches which might illustrate said ignorance, as I do
not claim at all to be an expert in async programming.

So, enough caveating, please consider this (more traditional) version
of our example:

  my $cv = AnyEvent->condvar;

  http_get('http://rest.api.example.com/-/product/12345', sub {
      my ($product) = @_;
      http_get('http://rest.api.example.com/-/product/suggestions?for_sku=12345', sub {
          my ($suggestions) = @_;
          http_get('http://rest.api.example.com/-/product/reviews?for_sku=12345', sub {
              my ($reviews) = @_;
              $cv->send({
                  product     => $product,
                  suggestions => $suggestions,
                  reviews     => $reviews,
              })
          }),
      });
  });

  my $all_product_info = $cv->recv;

Not only do we have deeply nested callbacks, but we have an enforced
order of operations. If you wanted to try and avoid that order of
operations, you might end up writing something like this:

   my $product_cv    = AnyEvent->condvar;
   my $suggestion_cv = AnyEvent->condvar;
   my $review_cv     = AnyEvent->condvar;

   http_get('http://rest.api.example.com/-/product/12345', sub {
       my ($product) = @_;
       $product_cv->send( $product );
   });

   http_get('http://rest.api.example.com/-/product/suggestions?for_sku=12345', sub {
       my ($suggestions) = @_;
       $suggestion_cv->send( $suggestions );
   });

   http_get('http://rest.api.example.com/-/product/reviews?for_sku=12345', sub {
       my ($reviews) = @_;
       $reviews_cv->send( $reviews )
   }),

   my $all_product_info = {
       product     => $product_cv->recv,
       suggestions => $suggestions_cv->recv,
       reviews     => $reviews_cv->recv
   };

But actually, this doesn't work either, while we do gain something by
allowing the C<http_get> calls to be run in whatever order works best,
we still end up still enforcing some order in the way we call C<recv>
on our three C<condvars> (Oh yeah, and we had to create and manage three
C<condvars> as well).

NOTE: Again, if can think of a better way to do this that I missed,
please let me know.

=head2 Chaining/Pipelining example

  my $cv = AnyEvent->condvar;

  fetch_it(
      'http://rest.api.example.com/-/user/search?access_level=admin'
  )->then(
      sub {
          my $admins = shift;
          when(
              map {
                  fetch_it( 'http://rest.api.example.com/-/user/' . url_encode( $_->{user_id} ) )
              } @$admins
          );
      }
  )->then(
      sub { $cv->send( @_ ) },
      sub { $cv->croak( 'ERROR' ) }
  );

  my @all_admins = $cv->recv;

So one of the real benefits of the Promise pattern is how it allows
you to write code that flows and reads more like synchronous code
by using the chaining nature of Promises. In example above we are
first fetching a list of users whose access level is 'admin', in
our fictional web-service we get back a list of JSON objects with
only minimal information, just a user_id and full_name for instance.
From here we can then loop through the results and fetch the full
user object for each one of these users, passing all of the promises
returned by C<fetch_it> into C<when>, which itself returns a promise.

So despite being completely asynchronous, this code reads much like
a blocking synchronous version would read, from top to bottom.

  my @all_admins;
  try {
      my $admins = fetch_it( 'http://rest.api.example.com/-/user/search?access_level=admin' );
      @all_admins = map {
          fetch_it( 'http://rest.api.example.com/-/user/' . url_encode( $_->{user_id} ) )
      } @$admins;
  } catch {
      die $_;
  };
  # do something with @all_admins ...

The only difference really are the C<then> wrappers and the way in
which we handle errors, but even that is very similar since we are
not including an error callback in the first C<then> and allowing
the errors to bubble till the final C<then>, which maps very closely
to the C<try/catch> block. And of course the Promise version runs
asynchronously and reaps all the benefits that brings.

=head2 Conclusion

I hope this has helped you to understand Promises as a pattern for
asynchronous programming and to illustrate the benefits and control
they bring to it.

=head1 EXPORTS

=over 4

=item C<when( @promises )>

The only export for this module is the C<when> function, which
accepts an array of L<Promises::Promise> objects and then
returns a L<Promises::Promise> object which will be called
once all the C<@promises> have completed (either as an error
or as a success). The eventual result of the returned promise
object will be an array of all the results (or errors) of each
of the C<@promises> in the order in which they where passed
to C<when> originally.

=back

=head1 SEE ALSO

=over 4

=item "You're Missing the Point of Promises" L<https://gist.github.com/3889970>

=item L<http://wiki.commonjs.org/wiki/Promises/A>

=item L<https://github.com/promises-aplus/promises-spec>

=item L<http://docs.scala-lang.org/sips/pending/futures-promises.html>

=back







