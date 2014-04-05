package Movie;

use strict;
use Digest::SHA1 qw( sha1_hex );

my $default_entry = { 
     title  => 'default title',
     year   => '1900',
     format => 'VHS',
     stars  => [],
};

my @mandatory = keys $default_entry;

sub new {
  my( $class, $args ) = @_;
  ref $args == 'HASH' or die __PACKAGE__ . " : malformed input";
  my $self = {};
  bless $self;
  for my $method ( keys %$args ) {
    $self->can($method) or die __PACKAGE__ . " : method $method unimplemented";
    eval { $self->$method( $args->{$method} ) };
    $@ and die __PACKAGE__ . " : new $method died : $@";
  }
  for ( @mandatory ) {
    exists $args->{$_} or die __PACKAGE__ . " : method $_ not specified";
  }
  $self->digest();
  $self;
}

sub title {
  my( $self, $data ) = @_;
  my $msg = __PACKAGE__ . " : method title bad input";
  ref $data and die $msg; # simple scalar for title 
  if( $data ) { # setter
    $data =~ tr/:/ /;
    $data =~ /^[,\&_-\w ]+$/ or die "$msg : $data"; # no tabs or newlines 
    $self->{title} = $data;
  } else {  # getter
    exists $self->{title} and return $self->{title};
  }
  return undef;
}

sub year {
  my( $self, $data ) = @_;
  my $msg = __PACKAGE__ . " : method year bad input";
  ref $data and die $msg; # simple scalar for year
  if( $data ) { # setter
    $data =~ /^\d{4}$/ or die $msg; # only 4 digit year accepted
    $self->{year} = $data;
  } else {  # getter
    exists $self->{year} and return $self->{year};
  }
  return undef;
}

sub format {
  my( $self, $data ) = @_;
  my $msg = __PACKAGE__ . " : method format bad input";
  ref $data and die $msg; # simple scalar for format 
  if( $data ) { # setter
    $data =~ /^[_-\w ]+$/ or die $msg; # no tabs or newlines allowed
    $self->{format} = $data;
  } else {  # getter
    exists $self->{format} and return $self->{format};
  }
  return undef;
}

sub stars {
  my( $self, $ray ) = @_;
  my $msg = __PACKAGE__ . " : method stars bad input";
  if( $ray ) {
    ref $ray == 'ARRAY' or die $msg; # need array ref
    $self->{stars} = [];
    for ( @$ray ) {
      tr/\./ /;
      /^[\w ]+$/ or die "$msg : $_"; # no tabs or newlines allowed
      push @{$self->{stars}}, $_;
    }
  } else {
    exists $self->{stars} and return $self->{stars}; #as reference
  }
  return undef;
}

sub display {
  my( $self ) = @_;
  # use accessors to build report
  my $t = $self->title();
  my $y = $self->year();
  my $f = $self->format();
  my $s = $self->stars();
  my $starlist = join( ", ", @$s );
  return "\n -- $t $y $f -- \n\tstarring: $starlist\n";
}

sub digest {  # setter and getter
  my( $self ) = @_;
  my $hash = substr( sha1_hex( $self->{title} ), 0, 6 );
  $self->{digest} = $hash;
}
  
1;
