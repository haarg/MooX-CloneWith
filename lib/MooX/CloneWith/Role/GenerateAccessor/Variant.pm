package MooX::CloneWith::Role::GenerateAccessor::Variant;
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
  if (my $clone_type = $args{type}) {
    install default_clone_type => sub { $clone_type };
  }

  with 'MooX::CloneWith::Role::GenerateAccessor';
}

1;
