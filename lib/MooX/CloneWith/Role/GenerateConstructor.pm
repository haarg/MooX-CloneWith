package MooX::CloneWith::Role::GenerateConstructor;
use Sub::Quote qw(quote_sub unquote_sub quotify sanitize_identifier);
use Sub::Defer qw(defer_sub);
use Carp;
use Moo::Role;

sub clone_method { 'clone_with' }
sub default_clone_type { 'copy' }

after install_delayed => sub {
  my ($self) = @_;
  $self->install_delayed_clone;
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
  +{
    map {; $_ => $spec->{$_} }
    grep !$self->_clone_type($spec->{$_}),
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
  my %test;
  NAME: foreach my $name (sort keys %$spec) {
    my $attr_spec = $spec->{$name};
    next
      unless $self->_clone_type($attr_spec);
    $test{$name} = $attr_spec;
  }
  join '', map {
    my $attr_spec = $test{$_};
    my $test_arg = exists $attr_spec->{init_arg} ? $attr_spec->{init_arg} : $_;
    my $test = (defined $test_arg ? '!exists '.$source.'->{'.quotify($test_arg).'}' : undef);
    $self->_generate_attr_clone($from, $to, $_, $attr_spec, $test, $test_arg);
  } sort keys %test;
}

# the rest of this should probably be on an accessor generator role
sub _generate_attr_clone {
  my ($self, $from, $to, $attr, $spec, $test, $test_arg) = @_;
  my $ag = $self->accessor_generator;
  my $type = $self->_clone_type($spec);
  $test = ($test ? "$test && " : '')
    . $ag->_generate_simple_has($from, $_);
  my $source = $self->_generate_clone_type($attr,
    $ag->_generate_simple_get($from, $attr), $type);
  my $set = $ag->_generate_simple_set($to, $attr, $spec, $source);
  "($test and $set),\n";
}

sub _generate_clone_type {
  my ($self, $attr, $source, $type) = @_;
  if ($type eq 'copy') {
    return $source;
  }
  elsif (ref $type && eval { \&$type }) {
  }
  elsif ($self->can(my $method = '_generate_clone_type_'.$type)) {
    $type = $self->$method($attr);
  }
  else {
    croak "Unknown clone type $type for $attr";
  }
  my $var = '$_clone_captures_for_'.sanitize_identifier($attr);
  $self->{captures}{$var} = \$type;
  return $var.'->('.$source.')';
}

sub _generate_clone_type_clone {
  my ($self, $attr) = @_;
  my $clone_method = $self->clone_method;
  sub {
    my $v = shift;
    my $vtype = ref $v;
    return
        !$vtype ? $v
      : $vtype eq "Regexp" ? $v
      : Scalar::Util::blessed($v) ? (
          ( $clone_method ne 'clone_with' && $v->can($clone_method) ) ? $v->$clone_method
        : $v->can("clone_with")  ? $v->clone_with
        : $v->can("clone")       ? $v->clone
        : ($v->can("STORABLE_freeze") && $v->can("STORABLE_thaw"))
          ? ((require Storable), Storable::dclone($v))
        : Carp::croak("Can't clone attribute $attr: $v")
      )
      : $vtype eq "ARRAY" ? [@$v]
      : $vtype eq "HASH"  ? {%$v}
      : ($vtype eq "SCALAR" || $vtype eq "REF" || $vtype eq "VSTRING" || $vtype eq "LVALUE")
        ? \(my ($c) = $$v)
      : $v;
  };
}

sub _generate_clone_type_deep {
  my ($self, $attr) = @_;
  my $clone = $self->_generate_clone_type_clone($attr);
  sub {
    my $vo = shift;
    my @clone = (\$vo);
    while (my $vref = pop @clone) {
      my $v = $$vref = $clone->($$vref);
      my $vtype = ref $v;
      push @clone,
        Scalar::Util::blessed($v) ? ()
        : $vtype eq "ARRAY" ? \(@$v)
        : $vtype eq "HASH"  ? \(values %$v)
        : $vtype eq "REF"   ? $v
        : ();
    }
    $vo;
  };
}

sub _clone_type {
  my ($self, $spec) = @_;
  exists $spec->{clone} ? (
    (($spec->{clone}||0) eq 1) ? 'copy' : $spec->{clone}
  ) : $self->default_clone_type;
}

1;
