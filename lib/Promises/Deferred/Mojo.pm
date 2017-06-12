package Promises::Deferred::Mojo;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use Mojo::IOLoop;

sub notify_callback {
    Promises::Deferred::_invoke_cbs_callback();
}

sub do_notify {
    Mojo::IOLoop->timer(0, \&notify_callback);
}

sub get_notify_sub {
    return \&do_notify;
}

1;

__END__

=head1 SYNOPSIS

    use Promises backend => ['Mojo'], qw[ deferred collect ];

    # ... everything else is the same

=head1 DESCRIPTION

The "Promise/A+" spec strongly suggests that the callbacks
given to C<then> should be run asynchronously (meaning in the
next turn of the event loop), this module provides support for
doing so using the L<Mojo::IOLoop> module.

Module authors should not care which event loop will be used but
instead should just the Promises module directly:

    package MyClass;

    use Promises qw(deferred collect);

End users of the module can specify which backend to use at the start of
the application:

    use Promises -backend => ['Mojo'];
    use MyClass;

B<Note:> If you are using Mojolicious with the L<EV> event loop, then you
should use the L<Promises::Deferred::EV> backend instead.

=cut

