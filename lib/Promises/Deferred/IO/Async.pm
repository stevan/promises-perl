package Promises::Deferred::IO::Async;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: IO::Async implementation of Promises
$Promises::Deferred::IO::Async::VERSION = '1.00';
use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Timer::Countdown;

use parent 'Promises::Deferred';

our $Loop = IO::Async::Loop->new;

sub _notify_backend {
    my ( $self, $callbacks, $result ) = @_;
    $Loop->add(
        IO::Async::Timer::Countdown->new( delay => 0, on_expire => sub {
            $_->(@$result) for @$callbacks;
        })->start
    );
}

sub _timeout {
    my ( $self, $timeout, $callback ) = @_;

    my $timer = IO::Async::Timer::Countdown->new(
        delay => $timeout,
        on_expire => $callback,
    );
    
    $Loop->add( $timer->start );

    return sub { $timer->stop };
}

1;

__END__

=pod

=head1 NAME

Promises::Deferred::IO::Async - IO::Async implementation of Promises

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    use Promises backend => ['IO::Async'], qw[ deferred collect ];

    # ... everything else is the same

=head1 DESCRIPTION

Uses L<IO::Async> as the async engine for the promises.

The L<IO::Async::Loop> loop used by default is the one given by
C<<IO::Async::Loop->new>>. It can be queried and modified via the global
variable C<$Promises::Deferred::IO::Async::Loop>.

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2014, 2012 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
