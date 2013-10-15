use strict;
use warnings;
use Promises 'when';
use Test::More 0.89;
use Test::Exception;

sub do_it {
    my $d = Promises::Deferred->new;
    $d->reject('fail'); # this would usually be called later on, asynchronously,
                        # but we just do it right away for simplicity's sake
    $d->promise;
}

{
    my $p;
    lives_ok {
        $p = do_it->then(
            sub { die { success => \@_ } },
            sub { die { fail    => \@_ } },
        );
    } "Exception was handled";

    is $p->status, Promises::Deferred->REJECTED, "Promise was rejected";
    is_deeply $p->result, [{ fail => ['fail'] }];
}

{
    my $p;
    lives_ok {
        $p = when(do_it)->then(
            sub { die { success => \@_ } },
            sub { die { fail    => \@_ } },
        );
    } "Exception was handled";

    is $p->status, Promises::Deferred->REJECTED, "Promise was rejected";
    is_deeply $p->result, [{ fail => ['fail'] }];
}

done_testing;
