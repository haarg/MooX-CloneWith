package MooX::CloneWith::Role::GenerateConstructor::Variant;
use strict;
use warnings;

use Package::Variant 1.002
  importing => ['Moo::Role'],
  subs => [ qw(with) ],
;

sub make_variant {
  my ($class, $target_package, %args) = @_;

  my $clone_method = $args{method};

  install clone_method => sub { $clone_method };
  with 'MooX::CloneWith::Role::GenerateConstructor';
}

1;
