package Promises::Promise;

# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

sub then    { ${shift()}->then(@_) }
sub chain   { ${shift()}->chain(@_) }
sub catch   { ${shift()}->catch(@_) }
sub done    { ${shift()}->done(@_) }
sub finally { ${shift()}->finally(@_) }
sub status  { ${shift()}->status }
sub result  { ${shift()}->result }

sub is_unfulfilled { ${shift()}->is_unfulfilled }
sub is_fulfilled   { ${shift()}->is_fulfilled }
sub is_failed      { ${shift()}->is_failed }
sub is_done        { ${shift()}->is_done }

sub is_in_progress { ${shift()}->is_in_progress }
sub is_resolved    { ${shift()}->is_resolved }
sub is_rejected    { ${shift()}->is_rejected }

1;

__END__

=head1 DESCRIPTION

Promise objects are typically not created by hand, they
are typically returned from the C<promise> method of
a L<Promises::Deferred> instance. It is best to think
of a L<Promises::Promise> instance as a handle for
L<Promises::Deferred> instances.

Most of the documentation here points back to the
documentation in the L<Promises::Deferred> module.

Additionally L<Promises::Cookbook::GentleIntro> contains a long
explanation of how this module, and all its components
are meant to work together.

=head1 METHODS

=over 4

=item C<then( $callback, $error )>

This calls C<then> on the proxied L<Promises::Deferred> instance.

=item C<chain( @thens )>

This calls C<chain> on the proxied L<Promises::Deferred> instance.

=item C<catch( $error )>

This calls C<catch> on the proxied L<Promises::Deferred> instance.

=item C<done( $callback, $error )>

This calls C<done> on the proxied L<Promises::Deferred> instance.

=item C<finally( $callback )>

This calls C<finally> on the proxied L<Promises::Deferred> instance.

=item C<status>

This calls C<status> on the proxied L<Promises::Deferred> instance.

=item C<result>

This calls C<result> on the proxied L<Promises::Deferred> instance.

=item C<is_unfulfilled>

This calls C<is_unfulfilled> on the proxied L<Promises::Deferred> instance.

=item C<is_fulfilled>

This calls C<is_fulfilled> on the proxied L<Promises::Deferred> instance.

=item C<is_failed>

This calls C<is_failed> on the proxied L<Promises::Deferred> instance.

=item C<is_in_progress>

This calls C<is_in_progress> on the proxied L<Promises::Deferred> instance.

=item C<is_resolved>

This calls C<is_resolved> on the proxied L<Promises::Deferred> instance.

=item C<is_rejected>

This calls C<is_rejected> on the proxied L<Promises::Deferred> instance.

=item C<is_done>

This calls C<is_done> on the proxied L<Promises::Deferred> instance.

=back
