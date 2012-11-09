package Promises;
# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use Promises::Deferred;

use Sub::Exporter -setup => {
    exports => [qw[ when ]]
};

sub when {
    my @promises = @_;

    my $all_done  = Promises::Deferred->new;
    my $results   = [];
    my $remaining = scalar @promises;

    foreach my $i ( 0 .. $#promises ) {
        my $p = $promises[$i];
        $p->then(
            sub {
                $results->[$i] = [ @_ ];
                $remaining--;
                if ( $remaining == 0 && $all_done->status ne $all_done->REJECTED ) {
                    $all_done->resolve( @$results );
                }
            },
            sub { $all_done->reject }
        );
    }

    $all_done->resolve( @$results ) if $remaining == 0;

    $all_done->promise;
}

1;

__END__

=head1 SYNOPSIS

  use Promises;

=head1 DESCRIPTION

