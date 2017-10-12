package Promises::Test::Mojo;

use Mojo::IOLoop;

sub new {
    return bless {}, shift;
}

sub start { Mojo::IOLoop->start }
sub stop  { Mojo::IOLoop->stop  }


1;
