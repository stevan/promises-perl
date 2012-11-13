#!perl

use strict;
use warnings;

use AnyEvent::HTTP;
use JSON::XS qw[ decode_json ];
use URL::Encode qw[ url_encode ];
use Promises qw[ when ];

sub fetch_it {
    my ($uri) = @_;
    my $d = Promises::Deferred->new;
    http_get $uri => sub { $d->resolve( decode_json( $_[0] ) ) };
    $d->promise;
}

my $cv = AnyEvent->condvar;

fetch_it(
    'http://en.wikipedia.org/w/api.php?action=opensearch&format=json&search=' . url_encode( $ARGV[0] )
)->then(
    sub {
        my $data = shift;
        when(
            map {
                fetch_it(
                    'http://en.wikipedia.org/w/api.php?action=query&format=json&titles='
                    . url_encode( $_ )
                    . '&prop=info&inprop=url'
                )
            } @{ $data->[1] }
        );
    },
    sub { $cv->croak( 'ERROR' ) }
)->then(
    sub { $cv->send( map { (values %{ $_->[0]->{'query'}->{'pages'} })[0]->{'fullurl'} } @_ ) },
    sub { $cv->croak( 'ERROR' ) }
);

use Data::Dumper; warn Dumper [ $cv->recv ];