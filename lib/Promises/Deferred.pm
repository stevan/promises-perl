package Promises::Deferred;

# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;
use Ref::Util qw/is_blessed_ref is_coderef/;
use Promises::Deferred::Default;
use Promises::Promise;

use constant {
    IN_PROGRESS => 'in progress',
    RESOLVED    => 'resolved',
    REJECTED    => 'rejected',
};
my %statuses= (
    0 => IN_PROGRESS,
    1 => RESOLVED,
    2 => REJECTED
);

my @pending_callbacks;
my $notify_sub= Promises::Deferred::Default->get_notify_sub;
sub _set_backend {
    my ( $class, $arg ) = @_;
    my $backend = $arg->[0] or return;
    unless ( $backend =~ s/^\+// ) {
        $backend = 'Promises::Deferred::' . $backend;
    }

    require Module::Runtime;
    Module::Runtime::use_module($backend) || return;

    $notify_sub= $backend->get_notify_sub;
}

# The callback our backends will call; this will handle all the promises that have pending notifications
sub _invoke_cbs_callback {
    while (my $cb= shift @pending_callbacks) {
        _invoke_cb($cb);

        # Explicit undef. Why? Because this is where we're going to spend almost all of our time:
        # deallocating Perl objects. So make it explicit as profilers will point people here.
        undef $cb;
    }
}

sub new {
    my ($class)= @_;
    return bless \{
        cb => [],
        state => 0,
        result => undef,
    }, $class;
}

sub deferred (;&) {
    my $self= __PACKAGE__->new();
    if (my $code= shift) {
        $self->resolve;
        return $self->then(sub{
            $code->($self);
        });
    }
    return $self;
}

sub _invoke_cbs {
    my ($cbs)= @_;
    return unless @$cbs;

    my $should_schedule= !@pending_callbacks;
    push @pending_callbacks, @$cbs;

    if ($should_schedule) {
        $notify_sub->();
    }
}

sub _invoke_cb {
    my $cb= shift;
    my $self= shift @$cb;

    if (my $invoke_callback= $cb->[$$self->{state}]) {
        eval {
            my @result= $invoke_callback->(@{$$self->{result}});
            if (my $next= $cb->[0]) {
                if (@result == 1 && is_blessed_ref($result[0]) && $result[0]->can('then')) {
                    if ($result[0]->isa("Promises::Promise")) {
                        _replace_promise($next, ${$result[0]});
                    } elsif ($result[0]->isa("Promises::Deferred")) {
                        _replace_promise($next, $result[0]);
                    } else {
                        $result[0]->then(sub {
                            $next->resolve(@_); ();
                        }, sub {
                            $next->reject(@_); ();
                        });
                    }
                } else {
                    $next->resolve(@result);
                }
            }
            1;
        } or do {
            my $error= $@ || '';
            $cb->[0]->reject($error) if $cb->[0];
        };

    } elsif ($cb->[0]) { # Passthrough
        if ($$self->{state} == 1) {
            $cb->[0]->resolve(@{$$self->{result}});
        } else {
            $cb->[0]->reject(@{$$self->{result}});
        }
    }

    1;
}

# Optimization: when returning a promise from a callback,
# we can replace the original promise with the new one.
# After all, its results, state and callback will all
# be equal to those of the newly returned promise.
sub _replace_promise {
    my ($orig_promise, $new_promise)= @_;
    my $orig_inner= $$orig_promise;
    my $new_inner= $$new_promise;

    # Do the replacement
    $$orig_promise= $$new_promise;

    my $callbacks= delete $orig_inner->{cb};
    if ($new_inner->{state}) {
        _invoke_cbs($callbacks);
    } else {
        push @{$new_inner->{cb}}, @$callbacks;
    }

    return;
}

sub then {
    my ($self, $ok, $nope)= @_;
    my $then= defined(wantarray) ? __PACKAGE__->new() : undef;

    my $cb_arr= [ $self, $then, $ok, $nope ];
    if ($$self->{state}) {
        _invoke_cbs([$cb_arr]);
        return $then;
    }
    push @{$$self->{cb}}, $cb_arr;

    return $then ? $then->promise : undef;
}

sub resolve {
    my $self= shift;
    if ($$self->{state}) {
        die "Cannot resolve twice!";
    }
    $$self->{state}= 1;
    $$self->{result}= [@_];
    _invoke_cbs(delete $$self->{cb});
    return $self;
}

sub reject {
    my $self= shift;
    if ($$self->{state}) {
        die "Cannot reject twice!";
    }
    $$self->{state}= 2;
    $$self->{result}= [@_];
    _invoke_cbs(delete $$self->{cb});
    return $self;
}

sub finally {
    my ($self, $sub)= @_;
    my ($ok, @result);
    my $finally= sub {
        return ($ok ? Promises::resolved(@result) : Promises::rejected(@result));
    };
    return $self->then(sub {
        $ok= 1; @result= @_;
        goto &$sub;
    }, sub {
        $ok= 0; @result= @_;
        goto &$sub;
    })->then($finally, $finally);
}

# Now for all the convenience methods
sub done    { &then; (); }
sub catch   { splice(@_, 1, 0, undef); goto &then; }
sub status  { $statuses{${$_[0]}->{state}} }
sub chain   { my $self= shift; $self= $self->then($_) for @_; return $self; }

# predicates for all the status possibilities
sub is_in_progress { ${$_[0]}->{state} == 0 }
sub is_resolved    { ${$_[0]}->{state} == 1 }
sub is_rejected    { ${$_[0]}->{state} == 2 }
sub is_done        { ${$_[0]}->{state} != 0 }

# the three possible states according to the spec ...
sub is_unfulfilled { ${$_[0]}->{state} == 0 }
sub is_fulfilled   { ${$_[0]}->{state} == 1 }
sub is_failed      { ${$_[0]}->{state} == 2 }

sub result         { ${$_[0]}->{result} }
sub promise        { Promises::Promise->_new($_[0]) }


1;

__END__

=head1 SYNOPSIS

  use Promises::Deferred;

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

=head1 DESCRIPTION

This class is meant only to be used by an implementor,
meaning users of your functions/classes/modules should
always interact with the associated promise object, but
you (as the implementor) should use this class. Think
of this as the engine that drives the promises and the
promises as the steering wheels that control the
direction taken.

=head1 CALLBACKS

Wherever a callback is mentioned below, it may take the form
of a coderef:

    sub {...}

or an object which has been overloaded to allow calling as a
coderef:

    use AnyEvent;

    my $cv = AnyEvent->cond_var;
    fetch_it('http://metacpan.org')
        ->then( sub { say "Success"; return @_ })
        ->then( $cv, sub { $cv->croak(@_)} )


=head1 METHODS

=over 4

=item C<new>

This will construct an instance, it takes no arguments.

=item C<promise>

This will return a L<Promises::Promise> that can be used
as a handle for this object. It will return a new one
every time it is called.

=item C<status>

This will return the status of the asynchronous
operation, which will be either 'in progress', 'resolved'
or 'rejected'. These three strings are also constants
in this package (C<IN_PROGRESS>, C<RESOLVED> and C<REJECTED>
respectively), which can be used to check these values.

=item C<result>

This will return the result that has been passed to either
the C<resolve> or C<reject> methods. It will always return
an ARRAY reference since both C<resolve> and C<reject>
take a variable number of arguments.

=item C<then( ?$callback, ?$error )>

This method is used to register two callbacks, both of which are optional. The
first C<$callback> will be called on success and it will be passed all the
values that were sent to the corresponding call to C<resolve>. The second,
C<$error> will be called on error, and will be passed all the values that were
sent to the corresponding C<reject>. It should be noted that this method will
always return a new L<Promises::Promise> instance so that you can chain things
if you like.

The success and error callbacks are wrapped in an C<eval> block, so you can
safely call C<die()> within a callback to signal an error without killing your
application. If an exception is caught, the next link in the chain will be
C<reject>'ed and receive the exception in C<@_>.

If this is the last link in the chain, and there is no C<$error> callback, the
error will be swallowed silently. You can still find it by checking the
C<result> method, but no action will be taken. If this is not the last link in
the chain, and no C<$error> is specified, we will attempt to bubble the error
to the next link in the chain. This allows error handling to be consolidated
at the point in the chain where it makes the most sense.

=item C<chain( @callbacks )>

Utility method that takes a list of callbacks and turn them into a sequence
of C<then>s. 

    $promise->then( sub { ...code A... } )
            ->then( sub { ...code B... } )
            ->then( sub { ...code C... } );

    # equivalent to

    $promise->chain( 
        sub { ...code A... } ),
        sub { ...code B... } ),
        sub { ...code C... } ),
    );


=item C<catch( $error )>

This method registers a a single error callback.  It is the equivalent
of calling:

    $promise->then( sub {@_}, $error );

=item C<done( $callback, ?$error )>

This method is used to register two callbacks, the first C<$callback> will be
called on success and it will be passed all the values that were sent to the
corresponding call to C<resolve>. The second, C<$error> is optional and will
be called on error, and will be passed the all the values that were sent to
the corresponding C<reject>.

Unlike the C<then()> method, C<done()> returns an empty list specifically to
break the chain and to avoid deep recursion.  See the explanation in
L<Promises::Cookbook::Recursion>.

=item C<finally( $callback )>

This method is like the C<finally> keyword in a C<try>/C<catch> block.  It
will execute regardless of whether the promise has been resolved or rejected.
Typically it is used to clean up resources, like closing open files etc. It
returns a L<Promises::Promise> and so can be chained. The return value is
discarded and the success or failure of the C<finally> callback will have no
effect on promises further down the chain.

=item C<resolve( @args )>

This is the method to call upon the successful completion of your asynchronous
operation, meaning typically you would call this within the callback that you
gave to the asynchronous function/method. It takes an arbitrary list of
arguments and captures them as the C<result> of this promise (so obviously
they can be retrieved with the C<result> method).

=item C<reject( @args )>

This is the method to call when an error occurs during your asynchronous
operation, meaning typically you would call this within the callback that you
gave to the asynchronous function/method. It takes an arbitrary list of
arguments and captures them as the C<result> of this promise (so obviously
they can be retrieved with the C<result> method).

=item C<is_in_progress>

This is a predicate method against the status value, it
returns true if the status is C<IN_PROGRESS>.

=item C<is_resolved>

This is a predicate method against the status value, it
returns true if the status is C<RESOLVED>.

=item C<is_rejected>

This is a predicate method against the status value, it
returns true if the status is C<REJECTED>.

=item C<is_done>

This is a predicate method against the status value, it
returns true if the status is either C<RESOLVED> or C<REJECTED>.

=item C<is_unfulfilled>

This is a predicate method against the status value, it
returns true if the status is still C<IN_PROGRESS>.

=item C<is_fulfilled>

This is a predicate method against the status value, it
returns true if the status is C<RESOLVED> or if the
status is C<RESOLVING>.

=item C<is_failed>

This is a predicate method against the status value, it
returns true of the status is C<REJECTED> or if the
status if C<REJECTING>.

=back



