package Promises::Deferred::IO::Async;
# ABSTRACT: IO::Async implementation of Promises

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

=head1 SYNOPSIS

    use Promises backend => ['IO::Async'], qw[ deferred collect ];

    # ... everything else is the same

=head1 DESCRIPTION

Uses L<IO::Async> as the async engine for the promises.

The L<IO::Async::Loop> loop used by default is the one given by
C<<IO::Async::Loop->new>>. It can be queried and modified via the global
variable C<$Promises::Deferred::IO::Async::Loop>.


=cut

