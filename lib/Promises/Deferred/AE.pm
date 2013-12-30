package Promises::Deferred::AE;

use strict;
use warnings;
use AE;
use Promises::Deferred;
our @ISA = qw(Promises::Deferred);

sub _notify {
    my ( $self, $callbacks, $result ) = @_;
    foreach my $cb (@$callbacks) {
        AE::postpone { $cb->(@$result) };
    }
    $self->{'resolved'} = [];
    $self->{'rejected'} = [];

}

1;
