package MooX::CloneWith::Role::GenerateAccessor;
use Sub::Quote qw(sanitize_identifier);
use Scalar::Util qw(refaddr blessed);
use Carp qw(croak);
use Moo::Role;

sub clone_method { 'clone_with' }
sub default_clone_type { 'copy' }

before generate_method => sub {
  my ($self, $into, $name, $spec, $quote_opts) = @_;
  my $clone = exists $spec->{clone} ? $spec->{clone}
    : $self->default_clone_type;

  $spec->{clone}
    = !$clone     ? undef
    : $clone eq 1 ? 'copy'
    : ($clone eq 'copy' || $clone eq 'clone' || $clone eq 'deep' ) ? $clone
    : (ref $clone && do { local $@; eval { \&{ $clone } } }) ? $clone
    : croak "Unknown clone type $clone for $name";
};

sub generate_clone {
  my $self = shift;
  $self->{captures} = {};
  my $code = $self->_generate_clone(@_);
  ($code, delete $self->{captures});
}

sub _generate_clone {
  my ($self, $from, $to, $attr, $spec, $test, $test_arg) = @_;
  my $type = $spec->{clone};
  $test = ($test ? "$test && " : '')
    . $self->_generate_simple_has($from, $_);
  my $source = $self->_generate_clone_type($attr,
    $self->_generate_simple_get($from, $attr), $type);
  my $set = $self->_generate_simple_set($to, $attr, $spec, $source);
  "($test and $set),\n";
}

sub _generate_clone_type {
  my ($self, $attr, $source, $type) = @_;
  if ($type eq 'copy') {
    return $source;
  }
  elsif (ref $type) {
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
      : blessed($v) ? (
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
  my %cache;
  sub {
    my $vo = shift;
    my @clone = (\$vo);
    while (my $vref = pop @clone) {
      my $va = refaddr $$vref;
      if (exists $cache{$va}) {
        $$vref = $cache{$va};
        next;
      }
      my $v = $cache{$va} = $$vref = $clone->($$vref);
      my $vtype = ref $v;
      push @clone,
        blessed($v) ? ()
        : $vtype eq "ARRAY" ? \(@$v)
        : $vtype eq "HASH"  ? \(values %$v)
        : $vtype eq "REF"   ? $v
        : ();
    }
    $vo;
  };
}

sub _is_clonable {
  my ($self, $spec) = @_;
  !!$spec->{clone};
}

1;
