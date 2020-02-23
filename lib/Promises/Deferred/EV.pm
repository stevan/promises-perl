package Promises::Deferred::EV;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use EV;

use parent 'Promises::Deferred';

# Before the pipe-based approach used below, there was an EV::timer-based
# approach for _notify_backend. The current code is much more performant:

# Original code (on a laptop on battery power):
# Backend:  Promises::Deferred::EV
# Benchmark: running one, two for at least 10 CPU seconds...
# Benchmark: running one, two for at least 10 CPU seconds...
#        one: 67 wallclock secs @ 1755.16/s (n=17692)
#        two: 53 wallclock secs @ 770.03/s (n=7785)

# New approach:
# Backend:  Promises::Deferred::EV
# Benchmark: running one, two for at least 10 CPU seconds...
#        one: 10 wallclock secs @ 10949.19/s (n=115076)
#        two: 10 wallclock secs @ 3964.58/s (n=41747)


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
    if  (! $socket_pid || $socket_pid != $$) {
        $socket_pid = $$;
        close($socket_send) if defined $socket_send;
        close($socket_recv) if defined $socket_recv;
        pipe($socket_recv, $socket_send);
        $socket_io = EV::io($socket_recv, EV::READ, \&_do_callbacks);
        $socket_io->keepalive(0);
    }

    # skip signalling when there are callbacks already waiting
    if (not @io_callbacks) {
        syswrite $socket_send, ' ';
    }
    push @io_callbacks, [ $_[2], $_[1] ];
}

sub _timeout {
    my ( $self, $timeout, $callback ) = @_;

    my $id = EV::timer $timeout, 0, $callback;

    return sub { undef $id };
}

1;

__END__

=head1 SYNOPSIS

    use Promises backend => ['EV'], qw[ deferred collect ];

    # ... everything else is the same

=head1 DESCRIPTION

The "Promise/A+" spec strongly suggests that the callbacks
given to C<then> should be run asynchronously (meaning in the
next turn of the event loop), this module provides support for
doing so using the L<EV> module.

Module authors should not care which event loop will be used but
instead should just the Promises module directly:

    package MyClass;

    use Promises qw(deferred collect);

End users of the module can specify which backend to use at the start of
the application:

    use Promises -backend => ['EV'];
    use MyClass;

