package AsyncUtil;

use strict;
use warnings;

use Promises qw[ deferred ];
use AnyEvent;

use Sub::Exporter -setup => {
    exports => [qw[
        delay_me
        delay_me_error
        perform_asyncly
    ]]
};

sub perform_asyncly {
    my ($input, $callback) = @_;
    my $d = deferred;
    my $w;
    $w = AnyEvent->timer(
        after => 0,
        cb    => sub {
            $d->resolve( $callback->( $input ) );
            undef $w;
        }
    );
    $d->promise;
}

sub delay_me {
    my $duration = shift;
    my $d = deferred;
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
    my $d = deferred;
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