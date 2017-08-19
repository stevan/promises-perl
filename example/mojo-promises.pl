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
my @titles;

foreach my $url (qw[ mojolicious.org www.cpan.org ]) {
    my $end = $delay->begin;
    $ua->get($url)->then(
        sub {
            my ($ua, $tx) = @_;
            push @titles, $tx->res->dom->at('title')->text;
            $end->();
        }
    );
}
$delay->wait;

print join "\n" => @titles;
print "\n";

1;

__END__
