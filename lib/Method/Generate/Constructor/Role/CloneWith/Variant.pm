package Method::Generate::Constructor::Role::CloneWith::Variant;
use strictures 1;

use Package::Variant 1.002
  importing => ['Moo::Role'],
  subs => [ qw(with) ],
;

sub make_variant {
  my ($class, $target_package, %args) = @_;

  my $clone_method = $args{method};

  install clone_method => sub { $clone_method };
  with 'Method::Generate::Constructor::Role::CloneWith';
}

1;
