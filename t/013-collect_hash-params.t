use Test::More tests => 3;

use Promises qw/ resolved collect_hash /;

collect_hash(
    a => 1,
    b => resolved( 'good' ),
)->then(sub{
    is_deeply +{ @_ }, { a => 1, b => 'good' }, 'scalars and scalar return promises are good'; 
});

collect_hash(
    a => 1,
    b => resolved(),
    c => resolved('good'),
)->then(sub{
    is_deeply +{ @_ }, { a => 1, b => undef, c => 'good' }, 'no value gets mapped to "undef"'; 
});

collect_hash(
    a => 1,
    b => resolved(1..5),
    c => resolved('good'),
)->catch(sub{
    my $error = $_[0];
    like shift() => qr/'collect_hash' promise returned more than one value/, "too many values";
});
