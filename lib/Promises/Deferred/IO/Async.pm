package Promises::Deferred::IO::Async;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: IO::Async implementation of Promises
$Promises::Deferred::IO::Async::VERSION = '1.02';
use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Timer::Countdown;

use parent 'Promises::Deferred';

our $Loop = IO::Async::Loop->new;

# Before the 'later'-based approach used below, there was an
# Async::IO::Timer::Countdown based approach for _notify_backend.
# The current code is much more performant:

# Original code
# Backend:  Promises::Deferred::IO::Async
# Benchmark: running one, two for at least 10 CPU seconds...
#        one: 41 wallclock secs @ 815.48/s (n=8954)
#        two: 31 wallclock secs @ 373.39/s (n=3760)

# New approach:
# Backend:  Promises::Deferred::IO::Async
# Benchmark: running one, two for at least 10 CPU seconds...
#        one: 11 wallclock secs @ 8436.69/s (n=88754)
#        two: 10 wallclock secs @ 3150.85/s (n=33273)


sub _notify_backend {
    my ( $self, $callbacks, $result ) = @_;
    $Loop->later(sub { $_->(@$result) for @$callbacks; });
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

version 1.02

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
