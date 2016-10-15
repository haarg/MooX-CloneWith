use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
  package ClonableBasic;
  use Moo;
  use MooX::CloneWith;
  has foo => (is => 'ro');
  has bar => (is => 'ro');
}

{
  my $o = ClonableBasic->new(foo => 1, bar => 2);
  my $o2 = $o->clone_with(foo => 5);
  is $o->foo, 1, 'initial attribute unmodified';
  is $o->bar, 2, 'initial attribute unmodified';
  is $o2->foo, 5, 'cloned attribute overwritten';
  is $o2->bar, 2, 'cloned attribute copied';
}

{
  package ClonableDeep;
  use Moo;
  use MooX::CloneWith;
  has foo => (is => 'ro');
  has bar => (is => 'ro', clone => 'clone');
  has baz => (is => 'ro', clone => 'deep');
}

{
  my $o = ClonableDeep->new(
    foo => {},
    bar => {
      buzz => {},
    },
    baz => {
      buzz => {},
    },
  );
  my $o2 = $o->clone_with;
  is $o->foo, $o2->foo, 'normal cloned attribute uses same reference';
  isnt $o->bar, $o2->bar, 'shallow cloned attribute gets new reference';
  is $o->bar->{buzz}, $o2->bar->{buzz},
    'shallow cloned attribute inner refs maintained';
  isnt $o->baz, $o2->baz, 'deep cloned attribute gets new reference';
  isnt $o->baz->{buzz}, $o2->baz->{buzz},
    'deep cloned attribute inner refs get new reference';
}

{
  package ClonableNoClone;
  use Moo;
  use MooX::CloneWith;
  has foo => (is => 'ro');
  has bar => (is => 'ro', clone => 0);
}

{
  my $o = ClonableNoClone->new(foo => 1, bar => 2);
  my $o2 = $o->clone_with(foo => 5);
  is $o->foo, 1, 'initial attribute unmodified';
  is $o->bar, 2, 'initial unclonable attribute unmodified';
  is $o2->foo, 5, 'cloned attribute overwritten';
  is $o2->bar, undef, 'unclonable attribute unset';
}

{
  package ClonableRequired;
  use Moo;
  use MooX::CloneWith;
  has foo => (is => 'ro', required => 1);
  has bar => (is => 'ro', clone => 0, required => 1);
}

{
  my $o = ClonableRequired->new(foo => 1, bar => 2);
  like exception { $o->clone_with }, qr/Missing required arguments: bar at/,
    'unclonable required attribute must be provided on clone';
}

done_testing;
