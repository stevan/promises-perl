package NoEV;

# prevents EV from loading

use lib \&_no_EV;

sub _no_EV {
    die "No EV" if $_[1] =~ /EV.pm$/;
    return undef;
}

1;
