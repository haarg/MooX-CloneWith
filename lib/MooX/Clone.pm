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
