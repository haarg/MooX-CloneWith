use strictures 1;
use Test::More;

{
  package ClonableRenamed;
  use Moo;
  use MooX::Clone method => 'another';
  has foo => (is => 'ro');
  has bar => (is => 'ro');
}

{
  my $o = ClonableRenamed->new(foo => 1, bar => 2);
  my $o2 = $o->another(foo => 5);
  is $o->foo, 1;
  is $o->bar, 2;
  is $o2->foo, 5;
  is $o2->bar, 2;
}

done_testing;
