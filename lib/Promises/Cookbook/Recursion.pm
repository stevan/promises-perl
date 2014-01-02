package Promises::Cookbook::Recursion;

# ABSTRACT: Examples of recursive asynchronous operations

=pod

=head1 SYNOPSIS

    package MyClass;

    use Promises backend => ['AE'], 'deferred';
    use Scalar::Util qw(weaken);

    sub new         {...}
    sub process     {...}
    sub is_finished {...}
    sub fetch_next  {...} # returns a promise

    sub fetch_all {
        my $self = shift;
        my $d    = deferred;

        my $weak_loop;
        my $loop = sub {
            if ( $self->is_finished ) {
                $d->resolve;
                return;
            }
            $self->fetch_next
                ->then( sub { $self->process(@_) } )
                ->then_discard(
                    $weak_loop,
                    sub { $d->reject(@_) }
                );
        };
        weaken( $weak_loop = $loop );
        $loop->();
        return $d->promise;
    }

    package main;

    my $cv  = AnyEvent->condvar;
    my $obj = MyClass->new(...);
    $obj->fetch_all->then(
        sub { $cv->send(@_)          },
        sub { $cv->croak('ERROR',@_) }
    );

    $cv->recv;

=head1 DESCRIPTION

While C<collect()> allows you to wait for multiple promises which
are executing in parallel, sometimes you need to execute each step
in order, by using promises recursively. For instance:

=over

=item 1

Fetch next page of results

=item 2

Process page of results

=item 3

If there are no more results, return success

=item 4

Otherwise, goto step 1

=back

However, recursion can result in very deep stacks and out of memory
conditions.  There are two important steps for dealing with recursion
effectively.

The first is to use one of the event-loop backends:

    use Promises backend => ['AE'], 'deferred';

While the default L<Promises::Deferred> implementation calls the
C<then()> callbacks synchronously, the event-loop backends call
the callbacks asynchronously in the context of the event loop.

However, each C<promise> passes its return value on to the next
C<promise> etc, so you still end up using a lot of memory with
recursion. We can avoid this by breaking the chain.

In our example, all we care about is whether all the steps in our
process completed successfully or not.  Each execution of steps 1 to
4 is independent. Step 1 does not need to receive the return value
from step 4.

We can break the chain by using C<then_discard()> instead of C<then()>.
While C<then()> returns a new C<promise> to continue the chain,
C<then_discard()> will execute either the success callback or the
error callback and discard the return result, rolling back the stack.

To work through the code in the L</SYNOPSIS>:

    sub fetch_all {
        my $self = shift;
        my $d    = deferred;

The deferred C<$d> will be used to signal success or failure of the
C<fetch_all()> method.

        my $weak_loop;
        my $loop = sub {
            if ( $self->is_finished ) {
                $d->resolve;
                return;
            }

If C<is_finished> returns a true value (eg there are no more results to fetch),
then we can resolve our promise, indicating success and exit the loop.

            $self->fetch_next
                ->then( sub { $self->process(@_) } )
                ->then_discard(
                    $weak_loop,
                    sub { $d->reject(@_) }
                );

Otherwise we fetch the next page of results and process them. If either of these steps
fail, then we signal failure by rejecting our deferred promise and exiting the loop.
If there is no failure, we recurse back into our loop.  However, this recursion happens
asynchronously in the event loop, so what this code actually does is schedule
another call to C<$loop> and exits the current execution of C<$loop>, discarding
any return results.


        };

        weaken( $weak_loop = $loop );

If we had used the C<$loop> variable inside the C<$loop> itself, we would have a
cyclic reference which could never be freed.  By using the weakend C<$weak_loop>
instead, Perl can clean up the C<$loop> variable correctly once it is no longer
in use.

We have to call the C<$loop> once to start the first execution:

        $loop->();

And we return a C<promise> to our caller, which will either be resolved once
all results have been fetched and processed, or rejected if an error happens
at any stage of execution.

        return $d->promise;
    }

=cut

__END__
