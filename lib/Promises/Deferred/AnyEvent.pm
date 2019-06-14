package Promises::Deferred::AnyEvent;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use AnyEvent;

use parent 'Promises::Deferred';

# Before the pipe-based approach used below, there was an
# AnyEvent->postpone-based approach for _notify_backend.
# The current code is much more performant:

# Original code (on a laptop on battery power):
# Backend:  Promises::Deferred::AnyEvent
# Benchmark: running one, two for at least 10 CPU seconds...
#        one: 47 wallclock secs @ 2754.62/s (n=32780)
#        two: 37 wallclock secs  @ 2450.45/s (n=24676)

# New approach:
# Backend:  Promises::Deferred::AnyEvent
# Benchmark: running one, two for at least 10 CPU seconds...
#        one: 10 wallclock secs @ 10182.12/s (n=106505)
#        two: 10 wallclock secs @ 3847.01/s (n=39855)


my ($socket_pid, $socket_send, $socket_recv, $socket_io,
    $read_buf, @io_callbacks);

sub _do_callbacks {
    my @cbs = @io_callbacks;
    @io_callbacks = ();
    sysread $socket_recv, $read_buf, 16;
    for my $cb_grp (@cbs) {
        my ($result, $cbs) = @$cb_grp;
        my @r = @$result;
        $_->(@r) for @$cbs;
    }
}

sub _notify_backend {
    if (! $socket_pid || $socket_pid != $$) {
        $socket_pid = $$;
        close($socket_send) if defined $socket_send;
        close($socket_recv) if defined $socket_recv;
        pipe($socket_recv, $socket_send);
        $socket_io = AnyEvent->io(
            fh => $socket_recv,
            poll => 'r',
            cb => \&_do_callbacks);
    }

    # skip signalling when there are callbacks already waiting
    if (not @io_callbacks) {
        syswrite $socket_send, ' ';
    }
    push @io_callbacks, [ $_[2], $_[1] ];
}

sub _timeout {
    my ( $self, $timeout, $callback ) = @_;

    my $id = AnyEvent->timer( after => $timeout,  cb => $callback );
    
    return sub { undef $id };
}

1;

__END__

=head1 SYNOPSIS

    use Promises backend => ['AnyEvent'], qw[ deferred collect ];

    # ... everything else is the same

=head1 DESCRIPTION

The "Promise/A+" spec strongly suggests that the callbacks
given to C<then> should be run asynchronously (meaning in the
next turn of the event loop), this module provides support for
doing so using the L<AnyEvent> module.

Module authors should not care which event loop will be used but
instead should just the Promises module directly:

    package MyClass;

    use Promises qw(deferred collect);

End users of the module can specify which backend to use at the start of
the application:

    use Promises -backend => ['AnyEvent'];
    use MyClass;

=cut

