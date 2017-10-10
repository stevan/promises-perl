package Promises::Test::EV;

use strict;
use warnings;

use EV;

sub new {
    return bless {}, shift;
}

sub start { EV::run }
sub stop  { EV::suspend }


1;
