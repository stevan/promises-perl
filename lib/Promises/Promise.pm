package Promises::Promise;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use Scalar::Util qw[ blessed ];
use Carp         qw[ confess ];

sub new {
    my ($class, $deferred) = @_;
    (blessed $deferred && $deferred->isa('Promises::Deferred'))
        || confess "You must supply an instance of Promises::Deferred";
    bless { 'deferred' => $deferred } => $class;
}

sub promise { shift }
sub then    { (shift)->{'deferred'}->then( @_ ) }
sub status  { (shift)->{'deferred'}->status     }
sub result  { (shift)->{'deferred'}->result     }

1;

__END__

=head1 SYNOPSIS

  use Promises::Promise;

=head1 DESCRIPTION

