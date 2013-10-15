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

sub new {
    my $class = shift;
    bless {
        resolved => [],
        rejected => [],
        status   => IN_PROGRESS,
    } => $class;
}

sub promise { Promises::Promise->new(shift) }
sub status  { (shift)->{'status'}  }
sub result  { (shift)->{'result'}  }

# predicates for all the status possiblities
sub is_in_progress { (shift)->{'status'} eq IN_PROGRESS }
sub is_resolved    { (shift)->{'status'} eq RESOLVED    }
sub is_rejected    { (shift)->{'status'} eq REJECTED    }

# the three possible states according to the spec ...
sub is_unfulfilled { (shift)->is_in_progress            }
sub is_fulfilled   { $_[0]->is_resolved  }
sub is_failed      { $_[0]->is_rejected  }

sub resolve {
    my $self   = shift;

    # return or die ?
    $self->is_in_progress or return;
    
    $self->{'result'} = [ @_ ];
    $self->{'status'}   = RESOLVED;
    $self->_notify;
    $self;
}

sub reject {
    my $self = shift;

    # return or die ?
    $self->is_in_progress or return;

    $self->{'result'} = [ @_ ];
    $self->{'status'}   = REJECTED;
    $self->_notify;
    $self;
}

sub then {
    my ($self, $callback, $error) = @_;

    (ref $callback && reftype $callback eq 'CODE')
        || confess "You must pass in a success callback"
	   if $callback;

    (ref $error && reftype $error eq 'CODE')
        || confess "You must pass in a error callback"
            if $error;

    # no default error handler

    my $d = (ref $self)->new;

    push @{ $self->{'resolved'} } => $self->_wrap( $d, $callback, 'resolve' );
    push @{ $self->{'rejected'} } => $self->_wrap( $d, $error,    'reject'  );

    $self->_notify if !$self->is_in_progress;

    $d->promise;
}

sub _wrap {
    my ($self, $d, $f, $method) = @_;
    return $f? sub {
        my @results = eval { $f->( @_ ) };
	if (my $err = $@){
	    $d->reject($err);
	}
        elsif ( (scalar @results) == 1 && blessed $results[0] && $results[0]->isa('Promises::Promise') ) {
            $results[0]->then(
                sub { $d->resolve( @_ ) },
                sub { $d->reject( @_ )  },
            );
        }
        else {
            $d->resolve( @results )
        }
    }: sub { $d->$method( @_ ) };
}

sub _notify {
    my ( $self ) = @_;

    my $result = $self->result;
    # cleaning both
    my @resolved = splice @{$self->{resolved}};
    my @rejected = splice @{$self->{rejected}};
    for my $cb ( $self->is_resolved? @resolved: @rejected ) {
        $cb->(@$result);
    }
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
as a handle for this object.

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

If this is the last link in the chain, and there is no
C<$error> callback, the error be silent. You can still
find it by checking the C<result> method, but no action
will be taken. If this is not the last link in the chain,
and no C<$error> is specified, we will attempt to bubble
the error to the next link in the chain. This allows
error handling to be consolidated at the point in the
chain where it makes the most sense.

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



