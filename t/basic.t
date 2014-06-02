use strictures 1;
use Test::More;
use Test::Fatal;

{
  package ClonableBasic;
  use Moo;
  use MooX::Clone;
  has foo => (is => 'ro');
  has bar => (is => 'ro');
}

{
  my $o = ClonableBasic->new(foo => 1, bar => 2);
  my $o2 = $o->but(foo => 5);
  is $o->foo, 1;
  is $o->bar, 2;
  is $o2->foo, 5;
  is $o2->bar, 2;
}

{
  package ClonableDeep;
  use Moo;
  use MooX::Clone;
  has foo => (is => 'ro');
  has bar => (is => 'ro', clone => 'deep');
}

{
  my $o = ClonableDeep->new(foo => {}, bar => {});
  my $o2 = $o->but;
  is $o->foo, $o2->foo;
  isnt $o->bar, $o2->bar;
}

{
  package ClonableNoClone;
  use Moo;
  use MooX::Clone;
  has foo => (is => 'ro');
  has bar => (is => 'ro', clone => 0);
}

{
  my $o = ClonableNoClone->new(foo => 1, bar => 2);
  my $o2 = $o->but(foo => 5);
  is $o->foo, 1;
  is $o->bar, 2;
  is $o2->foo, 5;
  is $o2->bar, undef;
}

{
  package ClonableRequired;
  use Moo;
  use MooX::Clone;
  has foo => (is => 'ro', required => 1);
  has bar => (is => 'ro', clone => 0, required => 1);
}

{
  my $o = ClonableRequired->new(foo => 1, bar => 2);
  like exception { $o->but }, qr/Missing required arguments: bar at/;
}

done_testing;
