use strict;
use warnings;
use Promises 'collect';
use Test::More 0.89;
use Test::Fatal;

sub do_it {
    my $d = Promises::Deferred->new;
    $d->reject('fail'); # this would usually be called later on, asynchronously,
                        # but we just do it right away for simplicity's sake
    $d->promise;
}

{
    my $e = exception {
        do_it->then(
            sub { die { success => \@_ } },
            sub { die { fail    => \@_ } },
        );
    };

    is_deeply $e, { fail => ['fail'] };
}

{
    my $e = exception {
        collect(do_it)->then(
            sub { die { success => \@_ } },
            sub { die { fail    => \@_ } },
        );
    };

    is_deeply $e, { fail => ['fail'] };
}

done_testing;
