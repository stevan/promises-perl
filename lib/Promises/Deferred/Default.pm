package Promises::Deferred::Default;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

sub do_notify {
    Promises::Deferred::_invoke_cbs_callback();
}

sub get_notify_sub {
    return \&do_notify;
}

1;

__END__

=head1 SYNOPSIS

    use Promises backend => ['Default'], qw[ deferred collect ];

    # ... everything else is the same

=head1 DESCRIPTION

The "Promise/A+" spec strongly suggests that the callbacks
given to C<then> should be run asynchronously (meaning in the
next turn of the event loop), this module provides support for running
without an event loop (not recommended, but still the default).

Module authors should not care which event loop will be used but
instead should just the Promises module directly:

    package MyClass;

    use Promises qw(deferred collect);

End users of the module can specify which backend to use at the start of
the application:

    use Promises -backend => ['Default'];
    use MyClass;

=cut

