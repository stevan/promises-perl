#!perl

use strict;
use warnings;

use AnyEvent::HTTP;
use JSON::XS qw[ decode_json ];
use Promises qw[ collect ];

sub fetch_it {
    my ($uri) = @_;
    my $d = Promises::Deferred->new;
    http_get $uri => sub { $d->resolve( decode_json( $_[0] ) ) };
    $d->promise;
}

my $cv = AnyEvent->condvar;

collect(
    map { fetch_it('http://en.wikipedia.org/w/api.php?action=opensearch&format=json&search=' . $_) } @ARGV
)->then(
    sub { $cv->send( @_ ) },
    sub { $cv->croak( 'ERROR' ) }
);

use Data::Dumper; warn Dumper [ $cv->recv ];