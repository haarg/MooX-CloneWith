package MooX::CloneWith;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

use Moo ();
use Moo::Role ();
use Carp;

sub import {
  my ($class, @opts) = @_;
  my $target = caller;

  my $c = Moo->_constructor_maker_for($target)
    or croak "MooX::CloneWith can only be used on Moo classes.";

  my $role = !@opts ? 'MooX::CloneWith::Role::GenerateConstructor' : do {
    require MooX::CloneWith::Role::GenerateConstructor::Variant;
    MooX::CloneWith::Role::GenerateConstructor::Variant->build_variant(@opts);
  };

  Moo::Role->apply_roles_to_object($c, $role);
  $c->install_delayed_clone;
}

1;
__END__

=head1 NAME

MooX::CloneWith - Provide a method for cloning Moo objects

=head1 SYNOPSIS

  package ClonableClass;
  use Moo;
  use MooX::CloneWith;

  has attr1 => (is => 'ro');
  has attr2 => (is => 'ro', clone => 0);
  has attr3 => (is => 'ro', clone => 'deep');
  has attr4 => (is => 'ro', clone => 0, required => 1);

  my $o = ClonableClass->new(attr1 => 1, attr2 => 2, attr3 => {}, attr4 => 4);
  my $o2 = $o->clone_with(attr4 => 5);
  # attr1 will be 1
  # attr2 will be unset
  # attr3 will have a new hashref with the same content as $o->attr3
  # attr4 will be 4.  if not provided to ->clone_with, will trigger an error

  # use alternate method name
  package ClonableClassRenamed;
  use Moo;
  use MooX::CloneWith method => 'but';

=head1 DESCRIPTION

C<MooX::CloneWith> provides a method that will clone an object, while setting new
attribute values.

The method generated accepts either hashref of attributes, or a list of key value
pairs.  This can be customized by implementing a C<CLONEARGS> method, which
will be given the list of paramters and is expected to return a hashref.

=head1 IMPORT OPTIONS

When importing B<MooX::CloneWith>, two options can be specified:

=over 4

=item method

The method name to generate to clone the class.  If not specified, the method
name will be C<clone_with>.

=item type

The type of cloning that will be used by default.  The default is C<copy>.

=back

=head1 ATTRIBUTE OPTIONS

=head2 clone

The clone option accepts several values for how to clone the attribute value.

=over 4

=item false

A false value means that the attribute will not be cloned.

=item copy

The attribute will be copied directly, including references.  This means that
the modifications to hashrefs or arrayrefs in the new object will also effect
the old object.

=item clone

The attribute value will be cloned.  New array and hash referenced will be
created, with copies of the old references values.

Objects will attempt to be cloned using either method given at import,
C<clone_with>, C<clone>, or using L<Storable> if hooks for it have been
implemented.  If none of these are available, an error will be thrown.

=item $coderef

An arbitrary code reference can be given, and it will be called to clone the
attribute.

=back

=head1 CAVEATS

=over 4

=item * Only works with full Moo classes

The clone method provided will not work properly if the class inherits from a
non-Moo class, or for subclasses that use Moose.

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2014 the MooX::CloneWith L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
