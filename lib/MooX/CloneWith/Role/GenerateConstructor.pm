package MooX::CloneWith::Role::GenerateConstructor;
use Sub::Quote qw(quote_sub quotify);
use Sub::Defer qw(defer_sub);
use Carp;
use Moo::Role;

sub clone_method { 'clone_with' }
sub clone_accessor_generator_role { 'MooX::CloneWith::Role::GenerateAccessor' }

after install_delayed => sub {
  my ($self) = @_;
  $self->install_delayed_clone;
};

before register_attribute_specs => sub {
  my $self = shift;
  my $ag = $self->accessor_generator;
  my $ag_role = $self->clone_accessor_generator_role;
  Moo::Role->apply_roles_to_object($ag, $ag_role)
    unless $ag->does($ag_role);
};

sub install_delayed_clone {
  my ($self) = @_;
  my $package = $self->{package};
  my $clone_method = $self->clone_method;
  defer_sub "${package}::${clone_method}" => sub {
    $self->_generate_clone_method(
      $package, $clone_method, $self->{attribute_specs}, { no_defer => 1 },
    );
  };
};

sub _required_clone_spec {
  my ($self, $spec) = @_;
  my $ag = $self->accessor_generator;
  +{
    map +($_ => $spec->{$_}),
    grep !$ag->_is_clonable($spec->{$_}),
    keys %$spec
  }
}

sub _generate_clone_method {
  my ($self, $into, $name, $spec, $quote_opts) = @_;
  local $self->{captures} = {};
  my $body
    = '    my $self = shift;'."\n"
    . '    my $class = ref($self);'."\n"
    . ( $into->can('CLONEARGS') ? (
       q{    my $args = $class->CLONEARGS(@_);}."\n"
      .q{    Carp::croak("CLONEARGS did not return a hashref") unless CORE::ref($args) eq 'HASH';}."\n"
    ) : $self->_generate_args)
    . $self->_check_required($self->_required_clone_spec($spec))
    . '    my $new = '.$self->construction_string.";\n"
    . $self->_assign_clone($spec, '$self', '$new', '$args')
    . $self->_assign_new($spec)
    . ( $into->can('BUILD')
      ? $self->buildall_generator->buildall_body_for($into, '$new', '$args')
      : ''
    )
    . '    (return $new);'."\n";
  quote_sub
    "${into}::${name}" => $body,
    $self->{captures}, $quote_opts||{},
  ;
}

sub _assign_clone {
  my ($self, $spec, $from, $to, $source) = @_;
  my $ag = $self->accessor_generator;
  join '',
    map {
      my $attr_spec = $spec->{$_};
      my $test_arg = exists $attr_spec->{init_arg} ? $attr_spec->{init_arg} : $_;
      my $test = (defined $test_arg ? '!exists '.$source.'->{'.quotify($test_arg).'}' : undef);
      $self->_cap_call(
        $ag->generate_clone($from, $to, $_, $attr_spec, $test, $test_arg)
      );
    }
    grep $ag->_is_clonable($spec->{$_}),
    sort keys %$spec;
}

1;
