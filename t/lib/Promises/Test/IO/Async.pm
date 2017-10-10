package Promises::Test::IO::Async;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

sub new {
    return bless {}, shift;
}

sub set_backend {
    Promises->_set_backend( 'IO::Async' );
}

sub start { $loop->run  }
sub stop  { $loop->stop }


1;
