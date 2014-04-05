package MovieCollection;

use strict;
use JSON;
use Movie;

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
  exists $args->{datafile} or die __PACKAGE__ . " : malformed input";
  my $self = {};
  bless $self;
  for my $method ( keys %$args ) {
    $self->can($method) or die __PACKAGE__ . " : method $method unimplemented";
    eval { $self->$method( $args->{$method} ) };
    $@ and die __PACKAGE__ . " : new $method died : $@";
  }
  $self->_load_storage();
  $self;
}

sub datafile {
  my( $self, $data ) = @_;
  my $msg = __PACKAGE__ . " : method datafile bad input";
  ref $data and die $msg; # simple scalar for datafile
  if( $data ) { # setter
    $self->{datafile} = $data;
  } else {  # getter
    exists $self->{datafile} and return $self->{datafile};
  }
  return undef;
}

sub add {
  my( $self, $o ) = @_;
  ref $o == 'Movie' or die __PACKAGE__ . " : add bad input";
  my $h = $o->{digest};
  $self->{movies}{$h} = $o;
}

sub delete {
  my( $self, $o ) = @_;
  my $h = $o->{digest};
  delete $self->{movies}{$h};
}

sub _sort_title {
  my( $self ) = @_;
    ( $self->{movies}{$a}{title} cmp $self->{movies}{$b}{title} )
}

sub list_title {
  my( $self ) = @_;
  my $rval  = sprintf( "%-50s%-6s%-6s\n", 'title', 'year', 'ID' );
     $rval .= sprintf( "%-50s%-6s%-6s\n", '-----', '----', '--' );
  for( sort _sort_title keys %{$self->{movies}} ) {
    my $y = $self->{movies}{$_}{year};
    my $t = $self->{movies}{$_}{title};
    my $d = $self->{movies}{$_}{digest};
    my $tmp = sprintf( "%-50s%-6s%-6s\n", $t, $y, $d );
    $rval .= $tmp;
  }
  $rval;
}

sub _sort_year {
  my( $self ) = @_;
    ( $self->{movies}{$a}{year} <=> $self->{movies}{$b}{year} ) ||
    ( $self->{movies}{$a}{title} cmp $self->{movies}{$b}{title} )
}

sub list_year {
  my( $self ) = @_;
  my $rval  = sprintf( "%-6s%-50s%-6s\n", 'year', 'title', 'ID' );
     $rval .= sprintf( "%-6s%-50s%-6s\n", '----', '-----', '--' );
  for( sort _sort_year keys %{$self->{movies}} ) {
    my $y = $self->{movies}{$_}{year};
    my $t = $self->{movies}{$_}{title};
    my $d = $self->{movies}{$_}{digest};
    my $tmp = sprintf( "%-6s%-50s%-6s\n", $y, $t, $d );
    $rval .= $tmp;
  }
  $rval;
}

sub search_title {
  my( $self, $needle ) = @_;
  my $rval  = "searching titles for <$needle> in collection\n";
     $rval .= sprintf( "%-50s%-6s\n", 'title', 'ID' );
     $rval .= sprintf( "%-50s%-6s\n", '-----', '--' );
  for( keys %{$self->{movies}} ) {
    my $t = $self->{movies}{$_}{title};
    $t =~ /$needle/i or next;
    my $d = $self->{movies}{$_}{digest};
    my $tmp = sprintf( "%-50s%-6s\n", $t, $d );
    $rval .= $tmp;
  }
  $rval;
}

sub search_star {
  my( $self, $needle ) = @_;
  my $rval  = "searching for <$needle> in stars collection\n";
     $rval .= sprintf( "%-50s%-6s\n", 'title', 'ID' );
     $rval .= sprintf( "%-50s%-6s\n", '-----', '--' );
  for my $m ( keys %{$self->{movies}} ) {
    for my $s ( @{$self->{movies}{$m}{stars}} ) {
      $s =~ /$needle/i or next;
      my $t = $self->{movies}{$m}{title};
      my $d = $self->{movies}{$m}{digest};
      my $tmp = sprintf( "%-50s%-6s\n", $t, $d );
      $rval .= $tmp;
      last;
    }
  }
  $rval;
}

sub _strip_blessing {
  my( $self, $rval ) = @_;
  for my $o ( keys %{$self->{movies}} ) {
    for my $k ( @mandatory ) {
      $rval->{$o}{$k} = $self->{movies}{$o}{$k}; # shallow copy
    }
    $rval->{$o}{digest} = $o;
  }
  $rval;
}

sub update_storage {
  my( $self ) = @_;
  my $json = encode_json( $self->_strip_blessing() );
  my $f = $self->{datafile};
  open my $FH, ">$f" or die "unable to open $f for output";
  print $FH $json or die "unable to print to $f";
  close $FH or die "unable to close $f";
}

sub _load_storage {
  my( $self ) = @_;
  my $f = $self->{datafile};
  -r $f or return undef;
  open my $FH, "$f" or die "unable to open $f for input";
  my $json = <$FH>;
  close $FH or die "unable to close $f";
  my $h = decode_json( $json );
  ref $h == 'HASH' or die "problem decoding json from $f";
  for ( keys %$h ) {
    my $m = Movie->new( $h->{$_} );
    $self->add( $m );
  }
}

sub moviebyID {
  my( $self, $id ) = @_;
  exists $self->{movies}{$id} or return undef;
  $self->{movies}{$id};
}

sub howmanymovies {
  my( $self ) = @_;
  scalar( keys %{$self->{movies}} );
}

1;
