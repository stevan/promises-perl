package Promises::Deferred::IO::Async;
# ABSTRACT: IO::Async implementation of Promises

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Timer::Countdown;

use parent 'Promises::Deferred';

our $Loop = IO::Async::Loop->new;

sub _notify_backend {
    my ( $self, $callbacks, $result ) = @_;
    $Loop->add(
        IO::Async::Timer::Countdown->new( delay => 0, on_expire => sub {
            $_->(@$result) for @$callbacks;
        })->start
    );
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
variable C<Promises::Deferred::IO::Async::Loop>.


=cut

