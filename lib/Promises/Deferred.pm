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

=head1 DESCRIPTION

Please see the documentation in C<Promises> for more info.

