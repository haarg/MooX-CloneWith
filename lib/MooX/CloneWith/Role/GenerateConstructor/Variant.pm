package MooX::CloneWith::Role::GenerateConstructor::Variant;
use strict;
use warnings;

use Package::Variant 1.002
  importing => ['Moo::Role'],
  subs => [ qw(with) ],
;

sub make_variant {
  my ($class, $target, %args) = @_;

  if (my $clone_method = $args{method}) {
    install clone_method => sub { $clone_method };
  }

  if (%args) {
    require MooX::CloneWith::Role::GenerateAccessor::Variant;
    my $ag_role = MooX::CloneWith::Role::GenerateAccessor::Variant->build_variant(%args);
    install clone_accessor_generator_role => sub { $ag_role };
  }

  with 'MooX::CloneWith::Role::GenerateConstructor';
}

1;
