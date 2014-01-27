#!perl

use strict;
use warnings;

use lib 't/lib';
use Promises qw(deferred);
use Test::More;

BEGIN {
    use_ok('Promises');
}

my @out;

my $then = Dummy::Then->new( \@out );

deferred->resolve->then(
    sub {
        push @out, 'Resolve';
        return $then;
    }
    )->then(
    sub { push @out, 'Resolve'; push @out, @_ },
    sub { push @out, 'Error' }
    );

$then->resolve('bar');

test( 'Resolve thenable', [ 'Resolve', 'Then resolved', 'Resolve', 'bar' ] );

@out = ();
deferred->resolve->then(
    sub {
        push @out, 'Resolve';
        return $then;
    }
    )->then(
    sub { push @out, 'Error' },
    sub { push @out, 'Reject'; push @out, @_; }
    );

$then->reject('bar');

test( 'Reject thenable', [ 'Resolve', 'Then rejected', 'Reject', 'bar' ] );

@out = ();
deferred->resolve->then(
    sub {
        push @out, 'Resolve';
        return $then;
    }
    )->finally( sub { push @out, 'Finally'; push @out, @_; } )->then(
    sub { push @out, 'Reject'; push @out, @_ },
    sub { push @out, 'Error' }
    );

$then->resolve('bar');
test( 'Finally resolve thenable',
    [ 'Resolve', 'Then resolved', 'Finally', 'bar', 'Reject', 'bar' ] );

@out = ();
@out = ();
deferred->resolve->then(
    sub {
        push @out, 'Resolve';
        return $then;
    }
    )->finally( sub { push @out, 'Finally'; push @out, @_ } )->then(
    sub { push @out, 'Error' },
    sub { push @out, 'Reject'; push @out, @_; }
    );

$then->reject('bar');

test( 'Finally reject thenable',
    [ 'Resolve', 'Then rejected', 'Finally', 'bar', 'Reject', 'bar' ] );

done_testing;

#===================================
sub test {
#===================================
    my ( $name, $expect ) = @_;

    #        diag "";
    #        diag "$name";
    #        diag "Expect: @$expect";
    #        diag "Got: @out";
    no warnings 'uninitialized';
    return fail $name unless @out == @$expect;
    for ( 0 .. @out ) {
        return fail $name unless $out[$_] eq $expect->[$_];
    }
    pass $name;

}

package Dummy::Then;

sub new {
    my ( $class, $out ) = @_;
    bless { out => $out }, $class;
}

sub then {
    my ( $self, $cb, $err ) = @_;
    $self->{cb}  = $cb;
    $self->{err} = $err;
    return ();
}

sub resolve {
    my $self = shift;
    push @{ $self->{out} }, 'Then resolved';
    $self->{cb}->(@_);
}

sub reject {
    my $self = shift;
    push @{ $self->{out} }, 'Then rejected';
    $self->{err}->(@_);
}

1

