#!perl

use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::IOLoop;


{
    package Mojo::UserAgent::Promises; 
    
    use strict;
    use warnings;

    use Promises qw[ deferred ];
    
    use Mojo::Base 'Mojo::UserAgent';

    sub start {
        my ($self, $tx, $cb) = @_;
        my $d = deferred;
        $self->SUPER::start( $tx, sub { $d->resolve( @_ ) });            
        return $d->then( $cb ) if $cb;
        return $d->promise;
    }
}

my $ua    = Mojo::UserAgent::Promises->new;
my $delay = Mojo::IOLoop->delay;

foreach my $url (qw[ mojolicio.us www.cpan.org ]) {
    $delay->begin;
    $ua->get($url)->then(
        sub {
            my ($ua, $tx) = @_;
            $delay->end( $tx->res->dom->at('title')->text );
        }
    );
}

my @titles = $delay->wait;

print join "\n" => @titles;
print "\n";

1;

__END__
