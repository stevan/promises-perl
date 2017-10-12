package Promises::Test::AnyEvent;

use strict;
use warnings;

use AnyEvent;

sub new {
    return bless {}, shift;
}

my $cv = AnyEvent->condvar;

sub start { $cv->recv }
sub stop  { $cv->send }


1;
