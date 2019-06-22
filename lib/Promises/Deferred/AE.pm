package Promises::Deferred::AE;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: An implementation of Promises in Perl
$Promises::Deferred::AE::VERSION = '1.02';
use strict;
use warnings;

use AE;

use parent 'Promises::Deferred';

# Before the pipe-based approach used below, there was an AE::postpone-based
# approach for _notify_backend. The current code is much more performant:

# Original code (on a laptop on battery power):
# Backend:  Promises::Deferred::AE
# Benchmark: running one, two for at least 10 CPU seconds...
#  one: 44 wallclock secs @ 3083.99/s (n=31210)
#  two: 29 wallclock secs @ 1723.66/s (n=17340)

# New approach:
# Backend:  Promises::Deferred::AE
# Benchmark: running one, two for at least 10 CPU seconds...
#  one: 11 wallclock secs @ 10457.90/s (n=108553)
#  two: 11 wallclock secs @ 3878.69/s (n=40959)


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
        $socket_io = AE::io($socket_recv, 0, \&_do_callbacks);
    }

    # skip signalling when there are callbacks already waiting
    if (not @io_callbacks) {
        syswrite $socket_send, ' ';
    }
    push @io_callbacks, [ $_[2], $_[1] ];
}

sub _timeout {
    my ( $self, $timeout, $callback ) = @_;

    my $id = AE::timer $timeout, 0, $callback;
    
    return sub { undef $id };
}

1;

__END__

=pod

=head1 NAME

Promises::Deferred::AE - An implementation of Promises in Perl

=head1 VERSION

version 1.02

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

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2014, 2012 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
