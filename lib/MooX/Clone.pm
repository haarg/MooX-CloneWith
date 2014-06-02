package MooX::Clone;
use strictures 1;

our $VERSION = '0.001000';
$VERSION = eval $VERSION;

use Moo ();
use Moo::Role ();

sub import {
  my ($class, @opts) = @_;
  my $target = caller;
  unless ($Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class}) {
    die "MooX::Clone can only be used on Moo classes.";
  }

  my $c = Moo::Role->apply_roles_to_object(
    Moo->_constructor_maker_for($target),
    'Method::Generate::Constructor::Role::WithClone',
  )->install_delayed_clone;
}

1;
__END__

=head1 NAME

MooX::Clone - Provide a method for cloning Moo objects

=head1 SYNOPSIS

    package MyClass;
    use Moo;
    use MooX::Clone;

    has attr1 => (is => 'ro');
    has attr2 => (is => 'ro');

    my $o = MyClass->new(attr1 => 1, attr2 => 2);
    my $o2 = $o->but(attr1 => 5);

=head1 DESCRIPTION

MooX::Clone provides a method that will clone an object, while setting new
attribute values.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2014 the MooX::Clone L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
