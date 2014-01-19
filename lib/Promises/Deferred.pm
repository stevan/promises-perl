package Promises::Deferred;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use Scalar::Util qw[ blessed reftype ];
use Carp         qw[ confess ];

use Promises::Promise;

use constant IN_PROGRESS => 'in progress';
use constant RESOLVED    => 'resolved';
use constant REJECTED    => 'rejected';
use constant RESOLVING   => 'resolving';
use constant REJECTING   => 'rejecting';

sub new {
    my $class = shift;
    bless {
        resolved => [],
        rejected => [],
        status   => IN_PROGRESS
    } => $class;
}

sub promise { Promises::Promise->new( shift ) }
sub status  { (shift)->{'status'}  }
sub result  { (shift)->{'result'}  }

# predicates for all the status possiblities
sub is_in_progress { (shift)->{'status'} eq IN_PROGRESS }
sub is_resolving   { (shift)->{'status'} eq RESOLVING   }
sub is_rejecting   { (shift)->{'status'} eq REJECTING   }
sub is_resolved    { (shift)->{'status'} eq RESOLVED    }
sub is_rejected    { (shift)->{'status'} eq REJECTED    }

# the three possible states according to the spec ...
sub is_unfulfilled { (shift)->is_in_progress            }
sub is_fulfilled   { $_[0]->is_resolved || $_[0]->is_resolving }
sub is_failed      { $_[0]->is_rejected || $_[0]->is_rejecting }

sub resolve {
    my $self   = shift;
    my $result = [ @_ ];
    $self->{'result'} = $result;
    $self->{'status'} = RESOLVING;
    $self->_notify( $self->{'resolved'}, $result );
    $self->{'status'}   = RESOLVED;
    $self;
}

sub reject {
    my $self = shift;
    my $result = [ @_ ];
    $self->{'result'} = $result;
    $self->{'status'} = REJECTING;
    $self->_notify( $self->{'rejected'}, $result );
    $self->{'status'}   = REJECTED;
    $self;
}

sub _notify_if_fulfilled {
    my $self = shift;
    if ( $self->status eq RESOLVED ) {
        $self->resolve( @{ $self->result } );
    }
    elsif ( $self->status eq REJECTED ) {
        $self->reject( @{ $self->result } );
    }
}

sub then {
    my ($self, $callback, $error) = @_;

    (ref $callback && reftype $callback eq 'CODE')
        || confess "You must pass in a success callback";

    (ref $error && reftype $error eq 'CODE')
        || confess "You must pass in a error callback"
            if $error;

    # if we don't get an error
    # handler, we need to chain
    # it automatically
    $error ||= sub { @_ };

    my $d = (ref $self)->new;

    push @{ $self->{'resolved'} } => $self->_wrap( $d, $callback, 'resolve' );
    push @{ $self->{'rejected'} } => $self->_wrap( $d, $error,    'reject'  );

    $self->_notify_if_fulfilled;
    $d->promise;
}

sub catch {
    my ( $self, $error ) = @_;

    ( ref $error && reftype $error eq 'CODE' )
        || confess "You must pass in a error callback";

    $self->then( sub {@_}, $error );
}

sub done {
    my ($self, $callback, $error) = @_;

    (ref $callback && reftype $callback eq 'CODE')
        || confess "You must pass in a success callback";

    (ref $error && reftype $error eq 'CODE')
        || confess "You must pass in a error callback"
            if $error;

    # if we don't get an error
    # handler, we need to chain
    # it automatically
    $error ||= sub { @_ };

    push @{ $self->{'resolved'} } => $callback;
    push @{ $self->{'rejected'} } => $error;

    $self->_notify_if_fulfilled;
    ();
}

sub finally {
    my ( $self, $callback ) = @_;

    ( ref $callback && reftype $callback eq 'CODE' )
        || confess "You must pass in a callback";

    my $d = ( ref $self )->new;

    my ( @result, $method );
    my $finish_d = sub { $d->$method(@result) };

    my $f = sub {
        ( $method, @result ) = @_;
        local $@;
        my ($p) = eval { $callback->(@_) };
        if ( $p && blessed $p && $p->isa('Promises::Promise') ) {
            return $p->then( $finish_d, $finish_d );
        }
        $finish_d->();

    };

    push @{ $self->{'resolved'} } => sub { $f->( 'resolve', @_ ) };
    push @{ $self->{'rejected'} } => sub { $f->( 'reject',  @_ ) };

    $self->_notify_if_fulfilled;
    $d->promise;

}

sub _wrap {
    my ($self, $d, $f, $method) = @_;
    return sub {
        local $@;
        my (@results,$error);
        eval { @results = do { $f->(@_)}; 1}
            || do { $error = $@ || 'Unknown error'};

        if ($error) {
            $d->reject( $error );
        } elsif ( (scalar @results) == 1 && blessed $results[0] && $results[0]->isa('Promises::Promise') ) {
            $results[0]->then(
                sub { $d->resolve( @{ $results[0]->result } ) },
                sub { $d->reject( @{ $results[0]->result } )  },
            );
        }
        else {
            $d->$method( @results )
        }
    }
}

sub _notify {
    my ($self, $callbacks, $result) = @_;
    $_->( @$result ) foreach @$callbacks;
    $self->{'resolved'} = [];
    $self->{'rejected'} = [];

}

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

=head1 METHODS

=over 4

=item C<new>

This will construct an instance, it takes no arguments.

=item C<promise>

This will return a L<Promises::Promise> that can be used
as a handle for this object. It will return a new one
every time it is called.

=item C<status>

This will return the status of the the asynchronous
operation, which will be either 'in progress', 'resolved'
or 'rejected'. These three strings are also constants
in this package (C<IN_PROGRESS>, C<RESOLVED> and C<REJECTED>
respectively), which can be used to check these values.

=item C<result>

This will return the result that has been passed to either
the C<resolve> or C<reject> methods. It will always return
an ARRAY reference since both C<resolve> and C<reject>
take a variable number of arguments.

=item C<then( $callback, ?$error )>

This method is used to register two callbacks, the first
C<$callback> will be called on success and it will be
passed all the values that were sent to the corresponding
call to C<resolve>. The second, C<$error> is optional and
will be called on error, and will be passed the all the
values that were sent to the corresponding C<reject>.
It should be noted that this method will always return
the associated L<Promises::Promise> instance so that you
can chain things if you like.

The success and error callbacks are wrapped in an C<eval> block,
so you can safely call C<die()> within a callback to signal
an error without killing your application. If an exception
is caught, the next link in the chain will be C<reject>'ed
and receive the exception in C<@_>.

If this is the last link in the chain, and there is no
C<$error> callback, the error be silent. You can still
find it by checking the C<result> method, but no action
will be taken. If this is not the last link in the chain,
and no C<$error> is specified, we will attempt to bubble
the error to the next link in the chain. This allows
error handling to be consolidated at the point in the
chain where it makes the most sense.

=item C<catch( $error )>

This method registers a a single error callback.  It is the equivalent
of calling:

    $promise->then( sub {@_}, $error );

=item C<done( $callback, ?$error )>

This method is used to register two callbacks, the first
C<$callback> will be called on success and it will be
passed all the values that were sent to the corresponding
call to C<resolve>. The second, C<$error> is optional and
will be called on error, and will be passed the all the
values that were sent to the corresponding C<reject>.

Unlike the C<then()> method, C<done()> returns an
empty list specifically to break the chain and to avoid
deep recursion.  See the explanation in
L<Promises::Cookbook::Recursion>.

Also unlike the C<then()> method, C<done()> callbacks are
not wrapped in an C<eval> block, so calling C<die()> is not
safe. What will happen if a C<done> callback calls
C<die()> depends on which event loop you are running: the pure
Perl L<AnyEvent::Loop> will throw an exception, while
L<EV> and L<Mojo::IOLoop> will warn and continue running.

=item C<finally( $callback )>

This method is like the C<finally> keyword in a C<try>/C<catch>
block.  It will execute regardless of whether the promise has
been resolved or rejected. Typically it is used to clean up
resources, like closing open files etc. It returns a L<Promises::Promise>
and so can be chained. The return value is discarded and the
success or failure of the C<finally> callback will have no
effect on promises further down the chain.

=item C<resolve( @args )>

This is the method to call upon the successful completion
of your asynchronous operation, meaning typically you
would call this within the callback that you gave to the
asynchronous function/method. It takes an arbitrary list
of arguments and captures them as the C<result> of this
promise (so obviously they can be retrieved with the
C<result> method).

=item C<reject( @args )>

This is the method to call when an error occurs during
your asynchronous operation, meaning typically you
would call this within the callback that you gave to the
asynchronous function/method. It takes an arbitrary list
of arguments and captures them as the C<result> of this
promise (so obviously they can be retrieved with the
C<result> method).

=item C<is_in_progress>

This is a predicte method against the status value, it
returns true of the status is C<IN_PROGRESS>.

=item C<is_resolving>

This is a predicte method against the status value, it
returns true of the status is C<RESOLVING>.

=item C<is_rejecting>

This is a predicte method against the status value, it
returns true of the status is C<REJECTING>.

=item C<is_resolved>

This is a predicte method against the status value, it
returns true of the status is C<RESOLVED>.

=item C<is_rejected>

This is a predicte method against the status value, it
returns true of the status is C<REJECTED>.

=item C<is_unfulfilled>

This is a predicte method against the status value, it
returns true of the status is still C<IN_PROGRESS>.

=item C<is_fulfilled>

This is a predicte method against the status value, it
returns true of the status is C<RESOLVED> or if the
status if C<RESOLVING>.

=item C<is_failed>

This is a predicte method against the status value, it
returns true of the status is C<REJECTED> or if the
status if C<REJECTING>.

=back



