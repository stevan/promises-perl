package Promises::Deferred::AE;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use AE;

my ($socket_pid, $socket_send, $socket_recv, $socket_io, $read_buf);

sub notify_callback {
    sysread $socket_recv, $read_buf, 16;
    Promises::Deferred::_invoke_cbs_callback();
}

sub do_notify {
    # If we forked, we can't trust our pipe anymore. Reset our state!
    if (!$socket_pid || $socket_pid != $$) {
        $socket_pid= $$;
        if ($socket_send) { close($socket_send); }
        if ($socket_recv) { close($socket_recv); }
        ($socket_send, $socket_recv, $socket_io)= ();
    }

    # First init, or init post-fork
    if (!$socket_io) {
        pipe($socket_recv, $socket_send);
        $socket_io= AE::io($socket_recv, 0, \&notify_callback);
    }

    # Write a single byte to our watcher
    syswrite $socket_send, "\0";
}

sub get_notify_sub {
    return \&do_notify;
}

1;

__END__

=head1 SYNOPSIS

    use Promises backend => ['AE'], qw[ deferred collect ];

    # ... everything else is the same

=head1 DESCRIPTION

The "Promise/A+" spec strongly suggests that the callbacks
given to C<then> should be run asynchronously (meaning in the
next turn of the event loop), this module provides support for
doing so using the L<AE> module.

Module authors should not care which event loop will be used but
instead should just the Promises module directly:

    package MyClass;

    use Promises qw(deferred collect);

End users of the module can specify which backend to use at the start of
the application:

    use Promises -backend => ['AE'];
    use MyClass;

=cut

