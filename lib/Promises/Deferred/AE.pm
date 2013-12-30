package Promises::Deferred::AE;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use AE;

use parent 'Promises::Deferred';

sub _notify {
    my ( $self, $callbacks, $result ) = @_;
    foreach my $cb (@$callbacks) {
        AE::postpone { $cb->(@$result) };
    }
    $self->{'resolved'} = [];
    $self->{'rejected'} = [];

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

=back

