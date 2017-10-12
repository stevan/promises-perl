package Promises::Deferred::Mojo;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use Mojo::IOLoop;

use parent 'Promises::Deferred';

sub _notify_backend {
    my ( $self, $callbacks, $result ) = @_;
    Mojo::IOLoop->timer(0,sub {
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

