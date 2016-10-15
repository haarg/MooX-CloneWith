package MooX::CloneWith;
use strictures 1;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

use Moo ();
use Moo::Role ();

sub import {
  my ($class, @opts) = @_;
  my $target = caller;
  unless ($Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class}) {
    die "MooX::CloneWith can only be used on Moo classes.";
  }

  my $c = Moo->_constructor_maker_for($target);

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
  # attr4 will be 4.  if not provided to ->but, will trigger an error


  # use alternate method name
  package ClonableClassRenamed;
  use Moo;
  use MooX::CloneWith method => 'but';

=head1 DESCRIPTION

C<MooX::CloneWith> provides a method that will clone an object, while setting new
attribute values.

=head1 CAVEATS

=over 4

=item * New attributes are processed by BUILDARGS

The arguments passed to C<< ->clone_with >> are processed by C<BUILDARGS> just like
arguments to C<new> are.  If the class has a C<BUILDARGS> method, it will have
to be written to account for this.

=item * Only works with full Moo classes

The but method provided will not work properly if the class inherits from a
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
