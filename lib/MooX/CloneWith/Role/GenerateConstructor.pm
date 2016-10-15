package MooX::CloneWith::Role::GenerateConstructor;
use Sub::Quote qw(quote_sub unquote_sub);
use Sub::Defer qw(defer_sub);
use Moo::Role;

sub clone_method { 'but' }

after install_delayed => sub {
  my ($self) = @_;
  $self->install_delayed_clone;
};

sub install_delayed_clone {
  my ($self) = @_;
  my $package = $self->{package};
  my $clone_method = $self->clone_method;
  defer_sub "${package}::${clone_method}" => sub {
    unquote_sub $self->generate_clone_method(
      $package, $clone_method, $self->{attribute_specs}
    );
  };
};

sub generate_clone_method {
  my ($self, $into, $name, $spec, $quote_opts) = @_;
  local $self->{captures} = {};
  my $body = '    my $self = shift;'."\n"
            .'    my $class = ref($self);'."\n";

  my $into_buildargs = $into->can('BUILDARGS');
  if ( $into_buildargs && $into_buildargs != \&Moo::Object::BUILDARGS ) {
      $body .= $self->_generate_args_via_buildargs;
  } else {
      $body .= $self->_generate_args;
  }
  $body .= $self->_check_required($self->_required_clone_spec($spec));
  $body .= '    my $new = '.$self->construction_string.";\n";
  $body .= $self->_assign_clone($spec);
  $body .= $self->_assign_new($spec);
  if ($into->can('BUILD')) {
    $body .= $self->buildall_generator->buildall_body_for(
      $into, '$new', '$args'
    );
  }
  $body .= '    return $new;'."\n";
  quote_sub
    "${into}::${name}" => $body,
    $self->{captures}, $quote_opts||{}
  ;
}

sub _assign_clone {
  my ($self, $spec) = @_;
  my $ag = $self->accessor_generator;
  my %test;
  foreach my $name (sort keys %$spec) {
    my $attr_spec = $spec->{$name};
    next
      if !$self->_is_clonable($attr_spec);
    $test{$name} = $name;
  }
  join '', map {
    my $attr_spec = $spec->{$_};
    local $ag->{captures} = {};
    my $test = $ag->_generate_simple_has('$self', $_);
    my $source = $ag->_generate_simple_get('$self', $_);
    if ($attr_spec->{clone} && $attr_spec->{clone} eq 'deep') {
      $source = $self->_generate_deep_clone($source);
    }
    my $set = $ag->_generate_simple_set('$new', $_, $attr_spec, $source);
    $self->_cap_call("$set if $test;\n", delete $ag->{captures});
  } sort keys %test;
}

sub _generate_deep_clone {
  my ($self, $source) = @_;
  my $clone_method = $self->clone_method;
  'do {'.
  '  my $v = '.$source.';'."\n".
  '    !ref($v)           ? $v'."\n".
  '  : Scalar::Util::blessed($v) ? ('."\n".
  ( $clone_method eq 'but' ? '' :
  '      $v->can("'.$clone_method.'")   ? $v->'.$clone_method."\n"
  ).
  '      $v->can("but")   ? $v->but'."\n".
  '    : $v->can("clone") ? $v->clone'."\n".
  '    : die "Can\'t clone $v"'."\n".
  '  )'."\n".
  '  : ref($v) eq "ARRAY" ? [%$v]'."\n".
  '  : ref($v) eq "HASH"  ? {%$v}'."\n".
  '  : $v;'."\n".
  '}';
}

sub _is_clonable {
  my ($self, $spec) = @_;
  return 0 if exists $spec->{clone} && !$spec->{clone};
  return 1;
}

sub _required_clone_spec {
  my ($self, $spec) = @_;
  +{
    map {; $_ => $spec->{$_} }
    grep !$self->_is_clonable($spec->{$_}),
    keys %$spec
  }
}

1;
