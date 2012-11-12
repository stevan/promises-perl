package AsyncUtil;

use strict;
use warnings;

use Promises;
use AnyEvent;

use Sub::Exporter -setup => {
    exports => [qw[
        delay_me
        delay_me_error
    ]]
};

sub delay_me {
    my $duration = shift;
    my $d = Promises::Deferred->new;
    my $w;
    $w = AnyEvent->timer(
        after => $duration,
        cb    => sub {
            $d->resolve( 'resolved after ' . $duration );
            undef $w;
        }
    );
    $d->promise;
}

sub delay_me_error {
    my $duration = shift;
    my $d = Promises::Deferred->new;
    my $w;
    $w = AnyEvent->timer(
        after => $duration,
        cb    => sub {
            $d->reject( 'rejected after ' . $duration );
            undef $w;
        }
    );
    $d->promise;
}

1;