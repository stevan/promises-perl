package Promises::Test::EV;

use strict;
use warnings;

use EV;

sub new {
    return bless {}, shift;
}

sub start { EV::run }
sub stop  {
    EV::break EV::BREAK_ALL;
    Promises::Deferred::EV->cleanup;
}


1;
