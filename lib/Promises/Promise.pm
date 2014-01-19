package Promises::Promise;

# ABSTRACT: An implementation of Promises in Perl

use strict;
use warnings;

use Scalar::Util qw[ blessed ];
use Carp qw[ confess ];

sub new {
    my ( $class, $deferred ) = @_;
    ( blessed $deferred && $deferred->isa('Promises::Deferred') )
        || confess "You must supply an instance of Promises::Deferred";
    bless { 'deferred' => $deferred } => $class;
}

sub then    { (shift)->{'deferred'}->then(@_) }
sub catch   { (shift)->{'deferred'}->catch(@_) }
sub done    { (shift)->{'deferred'}->done(@_) }
sub finally { (shift)->{'deferred'}->finally(@_) }
sub status  { (shift)->{'deferred'}->status }
sub result  { (shift)->{'deferred'}->result }

sub is_unfulfilled { (shift)->{'deferred'}->is_unfulfilled }
sub is_fulfilled   { (shift)->{'deferred'}->is_fulfilled }
sub is_failed      { (shift)->{'deferred'}->is_failed }

sub is_in_progress { (shift)->{'deferred'}->is_in_progress }
sub is_resolving   { (shift)->{'deferred'}->is_resolving }
sub is_rejecting   { (shift)->{'deferred'}->is_rejecting }
sub is_resolved    { (shift)->{'deferred'}->is_resolved }
sub is_rejected    { (shift)->{'deferred'}->is_rejected }

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

Additionally the L<Promises> module contains a long
explanation of how this module, and all it's components
are meant to work together.

=head1 METHODS

=over 4

=item C<new( $deferred )>

The constructor only takes one parameter and that is an
instance of L<Promises::Deferred> that you want this
object to proxy.

=item C<then( $callback, $error )>

This calls C<then> on the proxied L<Promises::Deferred> instance.

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

=item C<is_resolving>

This calls C<is_resolving> on the proxied L<Promises::Deferred> instance.

=item C<is_rejecting>

This calls C<is_rejecting> on the proxied L<Promises::Deferred> instance.

=item C<is_resolved>

This calls C<is_resolved> on the proxied L<Promises::Deferred> instance.

=item C<is_rejected>

This calls C<is_rejected> on the proxied L<Promises::Deferred> instance.

=back

