package Promises::Deferred::Mojo;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: An implementation of Promises in Perl
$Promises::Deferred::Mojo::VERSION = '1.05';
use strict;
use warnings;

use Mojo::IOLoop;

use parent 'Promises::Deferred';


# Before the next_tick-based approach used below, there was a
# Mojo::IOLoop->timer()-based approach for _notify_backend.
# The current code is more performant:

# Original code (using the Mojo::Reactor::EV backend):
# Backend:  Promises::Deferred::Mojo
# Benchmark: running one, two for at least 10 CPU seconds...
#        one: 46 wallclock secs @ 758.45/s (n=8032)
#        two: 44 wallclock secs @ 309.08/s (n=3097)


# New approach:
# Backend:  Promises::Deferred::Mojo
# Benchmark: running one, two for at least 10 CPU seconds...
#        one: 29 wallclock secs @ 1714.56/s (n=17197)
#        two: 24 wallclock secs @ 1184.80/s (n=12156)



sub _notify_backend {
    my ( $self, $callbacks, $result ) = @_;
    Mojo::IOLoop->next_tick(sub {
        foreach my $cb (@$callbacks) {
            $cb->(@$result);
        }
    });
}

sub _timeout {
    my ( $self, $timeout, $callback ) = @_;

    my $id = Mojo::IOLoop->timer( $timeout => $callback );
    
    return sub { Mojo::IOLoop->remove($id) };
}

1;

__END__

=pod

=head1 NAME

Promises::Deferred::Mojo - An implementation of Promises in Perl

=head1 VERSION

version 1.05

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

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025, 2017, 2014, 2012 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
