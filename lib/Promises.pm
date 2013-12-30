package Promises;

# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use Promises::Deferred;

use Sub::Exporter -setup => {
    collectors => ['backend'],
    exports    => [
        'deferred' => \'_build_deferred',
        'collect'  => \'_build_collect',
        'when'     => sub {
            my $class = shift;
            warn "The 'when' subroutine is deprecated, please use 'collect' instead.";
            return $class->_build_collect(@_);
        },
    ]
};

sub _build_backend {
    my ( $class, $col ) = @_;
    my $backend = $col->{backend} or return 'Promises::Deferred';
    $backend = $backend->[0];

    unless ( $backend =~ s/^\+// ) {
        $backend = 'Promises::Deferred::' . $backend;
    }
    require Module::Runtime;
    return Module::Runtime::use_module($backend);
}

sub _build_deferred {
    my ( $class, $name, $args, $col ) = @_;
    my $backend = $class->_build_backend($col);
    return sub { $backend->new }
}

sub _build_collect {
    my ( $class, $name, $args, $col ) = @_;
    my $backend = $class->_build_backend($col);
    return sub {
        my @promises = @_;

        my $all_done  = $backend->new;
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

        $all_done->resolve(@$results) if $remaining == 0;

        $all_done->promise;
    };
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

This module is an implementation of the "Promise" pattern for
asynchronous programming. Promises are meant to be a way to
better deal with the resulting callback spaghetti that can often
result in asynchronous programs.

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
next turn of the event loop). We do not do this because doing
so would bind us to a given event loop implementation, which
we very much want to avoid.

=head2 Relation to Promises/Futures in Scala

Scala has a notion of Promises and an associated idea of Futures
as well. The differences and similarities between this module
and the Promises found in Scalar are highlighted in depth in a
cookbook entry below.

=head2 Cookbook

I have begun moving the docs over into a Cookbook. While this
module is incredibly simple, the usage of it is quite complex
and deserves to be explained in detail. It is my plan to grow
this section to provide examples of the use of Promises in
a number of situations and with a number of different event
loops.

=over 1

=item L<Promises::Cookbook::SynopsisBreakdown>

This breaks down the example in the SYNOPSIS and walks through
much of the details of Promises and how they work.

=item L<Promises::Cookbook::TIMTOWTDI>

Promise are just one of many ways to do async programming, this
entry takes the Promises SYNOPSIS again and illustrates some
counter examples with various modules.

=item L<Promises::Cookbook::ChainingAndPipelining>

One of the key benefits of Promises is that it retains much of
the flow of a syncronous program, this entry illustrates that
and compares it with a syncronous (or blocking) version.

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

=item C<collect( @promises )>

The only export for this module is the C<collect> function, which
accepts an array of L<Promises::Promise> objects and then
returns a L<Promises::Promise> object which will be called
once all the C<@promises> have completed (either as an error
or as a success). The eventual result of the returned promise
object will be an array of all the results (or errors) of each
of the C<@promises> in the order in which they where passed
to C<collect> originally.

=item C<when( @promises )>

This is now deprecated, if you import this it will warn you
accordingly. Please switch all usage of C<when> to use C<collect>
instead.

=back

=head1 SEE ALSO

=over 4

=item "You're Missing the Point of Promises" L<http://domenic.me/2012/10/14/youre-missing-the-point-of-promises/>

=item L<http://wiki.commonjs.org/wiki/Promises/A>

=item L<https://github.com/promises-aplus/promises-spec>

=item L<http://docs.scala-lang.org/sips/pending/futures-promises.html>

=item L<http://monkey.org/~marius/talks/twittersystems/>

=back







