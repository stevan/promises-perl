#!perl

use strict;
use warnings;

use AnyEvent::HTTP;
use JSON::XS qw[ decode_json ];
use Promises qw[ when ];

sub fetch_it {
    my ($uri) = @_;
    my $d = Promises::Deferred->new;
    http_get $uri => sub { $d->resolve( decode_json( $_[0] ) ) };
    $d->promise;
}

my $cv = AnyEvent->condvar;

when(
    fetch_it('http://en.wikipedia.org/w/api.php?action=opensearch&format=json&search=foo'),
    fetch_it('http://en.wikipedia.org/w/api.php?action=opensearch&format=json&search=bar'),
    fetch_it('http://en.wikipedia.org/w/api.php?action=opensearch&format=json&search=baz')
)->then(
    sub { $cv->send( @_ ) },
    sub { $cv->croak( 'ERROR' ) }
);

use Data::Dumper; warn Dumper [ $cv->recv ];