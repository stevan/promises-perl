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
    my $self  = bless {
        resolved => [],
        rejected => [],
        status   => IN_PROGRESS,
        promise  => undef
    } => $class;
    $self->{'promise'} = Promises::Promise->new( $self );
    $self;
}

sub promise { (shift)->{'promise'} }
sub status  { (shift)->{'status'}  }
sub result  { (shift)->{'result'}  }

sub resolve {
    my $self   = shift;
    my $result = [ @_ ];
    $self->{'result'} = $result;
    $self->{'status'} = RESOLVING;
    $self->_notify( $self->{'resolved'}, $result );
    $self->{'resolved'} = [];
    $self->{'status'}   = RESOLVED;
    $self;
}

sub reject {
    my $self = shift;
    my $result = [ @_ ];
    $self->{'result'} = $result;
    $self->{'status'} = REJECTING;
    $self->_notify( $self->{'rejected'}, $result );
    $self->{'rejected'} = [];
    $self->{'status'}   = REJECTED;
    $self;
}

sub then {
    my ($self, $callback, $error) = @_;

    (ref $callback && reftype $callback eq 'CODE')
        || confess "You must pass in a success callback";

    (ref $error && reftype $error eq 'CODE')
        || confess "You must pass in a error callback";

    my $d = (ref $self)->new;

    push @{ $self->{'resolved'} } => $self->_wrap( $d, $callback, 'resolve' );
    push @{ $self->{'rejected'} } => $self->_wrap( $d, $error,    'reject'  );

    if ( $self->status eq RESOLVED ) {
        $self->resolve( @{ $self->result } );
    }

    if ( $self->status eq REJECTED ) {
        $self->reject( @{ $self->result } );
    }

    $d->promise;
}

sub _wrap {
    my ($self, $d, $f, $method) = @_;
    return sub {
        my $result = $f->( @_ );
        if ( blessed $result && $result->isa('Promises::Promise') ) {
            $result->then(
                sub { $d->resolve },
                sub { $d->reject  },
            );
        }
        else {
            $d->$method( $result )
        }
    }
}

sub _notify {
    my ($self, $callbacks, $result) = @_;
    $_->( @$result ) foreach @$callbacks;
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

=item C<then( $callback, $error )>

This method is used to register two callbacks, the first
C<$callback> will be called on success and it will be
passed all the values that were sent to the corresponding
call to C<resolve>. The second, C<$error> will be called
on error, and will be passed the all the values that were
sent to the corresponding C<reject>. It should be noted
that this method will always return the associated
L<Promises::Promise> instance so that you can chain
things if you like.

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

=back



