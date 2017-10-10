package Promises::Test::AE;

use strict;
use warnings;

use AE;

sub new {
    return bless {}, shift;
}

my $cv = AE::cv;

sub start { $cv->recv }
sub stop  { $cv->send }


1;
