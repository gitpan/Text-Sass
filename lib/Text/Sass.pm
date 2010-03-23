#########
# Author:        rmp
# Last Modified: $Date$
# Id:            $Id$
# Source:        $Source$
# $HeadURL$
#
package Text::Sass;
use strict;
use warnings;
use Carp;
use English qw(-no_match_vars);
use Text::Sass::Expr;
use Data::Dumper;

our $VERSION = q[0.5];

sub new {
  my ($class, $ref) = @_;

  if(!$ref) {
    $ref = {};
  }

  bless $ref, $class;
  return $ref;
}

sub css2sass {
  my ($self, $str) = @_;

  if(!ref $self) {
    $self = $self->new;
  }

  my $symbols = {};
  my $stash   = {};
  $self->_parse_css($str, $stash, $symbols);
  return $self->_stash2sass($stash, $symbols);
}

sub sass2css {
  my ($self, $str) = @_;

  if(!ref $self) {
    $self = $self->new;
  }

  my $symbols = {};
  my $stash   = {};
  $self->_parse_sass($str, $stash, $symbols);
#  use Data::Dumper; carp 'STASH ' . Dumper($stash);
#  use Data::Dumper; carp 'SYMBOLS ' . Dumper($symbols);
  return $self->_stash2css($stash, $symbols);
}

sub _parse_sass {
  my ($self, $str, $substash, $symbols) = @_;

  my $groups = [split /\n\s*?\n/smx, $str];

  for my $g (@{$groups}) {
    my @lines = split /\n/smx, $g;

    while(my $line = shift @lines) {
      #########
      # !x = y   variable declarations
      #
      $line =~ s{^!(\S+)\s*=\s*(.*?)$}{
        $symbols->{variables}->{$1} = $2;
        q[];
      }smxegi;

      #########
      # =x           and   =x(!var)
      #   bla                bla
      #
      # mixin declaration
      #
      $line =~ s{^=(.*?)$}{
        my $mixin_stash = {};
        my $remaining   = join "\n", @lines;
        @lines          = ();
        my $proto       = $1;
        my ($func)      = $1 =~ /^([^(]+)/smx;

        #########
        # mixins are interpolated later, so we just store the string here
        #
        $symbols->{mixins}->{$func} = "$proto\n$remaining\n";
#carp qq[STASHED MIXIN $func str=$symbols->{mixins}->{$func}];
        q[];
      }smxegi;

      #########
      # static +mixin
      #
      $line =~ s{^[+]([^(]+)$}{
        my $func      = $1;
        my $mixin_str = $symbols->{mixins}->{$func};

        $mixin_str    =~ s/^.*?\n//smx;
        my $result    = {};
        $self->_parse_sass($mixin_str, $result, $symbols);
        my $mixin_tag = (keys %{$result})[0];
        $substash->{$mixin_tag} = (values %{$result})[0];
#carp qq[STATIC MIXIN func=$func tag=$mixin_tag str=$mixin_str results=\n].Dumper($substash->{$mixin_tag});

        q[];
      }smxegi;

      #########
      # interpolated +mixin(value)
      #
      $line =~ s{^[+](.*?)[(](.*?)[)]$}{
        my ($func, $argstr) = ($1, $2);
        my $mixin_str  = $symbols->{mixins}->{$func};

        my $subsymbols = $symbols; # todo: correct scoping - is better as {%{$symbols}}
        my $values     = [split /\s*,\s*/smx, $argstr];
        my ($varstr)   = $mixin_str =~ /^.*?[(](.*?)[)]/smx;
        my $vars       = [split /\s*,\s*/smx, $varstr];
#carp q[VALUES = ].Dumper($values);
#carp q[VARS   = ].Dumper($vars);

        for my $var (@{$vars}) {
          $var =~ s/^!//smx;
#          carp qq[VAR=$var VAL=$values->[0]];

          $subsymbols->{variables}->{$var} = shift @{$values};
        }
#carp q[SUBSYMS=] . Dumper($subsymbols);
        $mixin_str    =~ s/^.*?\n//smx;
        my $result    = {};
        $self->_parse_sass($mixin_str, $result, $subsymbols);
#carp qq[DYNAMIC: result=].Dumper($result);
        $substash->{"+$func"} = $result;
#carp qq[DYNAMIC MIXIN func=$func argstr=$argstr tag=$mixin_tag str=$mixin_str results=\n].Dumper($substash->{$mixin_tag});

        q[];
      }smxegi;


      #########
      # .class
      # #id
      # element
      #   <following content>
      #
      $line =~ s{^([.#]?\S+)$}{
        my $remaining   = join "\n", @lines;
        @lines          = ();
        $substash->{$1} = {};
        $self->_parse_sass($remaining, $substash->{$1}, $symbols);
        q[];
      }smxegi;

      #########
      # static & dynamic attr: value
      #
      $line =~ s{^(\S+)\s*[:=]\s*(.*?)$}{
#carp qq[ATTR $1 = $2];
        $substash->{$1} = $2;
        q[];
      }smxegi;

      #########
      #   <indented sub-content>
      #
      $line =~ s{^[ ][ ](.*?)$}{
        my $remaining = join "\n", $1, @lines;
        @lines        = ();
        $self->_parse_sass($remaining, $substash, $symbols);
        q[];
      }smxegi;

      #########
      # // comments
      #
#      $line =~ s{\s*//(.*)}{
#        $substash->{__comments} ||= [];
#        push @{$substash->{__comments}}, $1;
#        q[];
#      }smxegi;
    }
  }

  return 1;
}

sub _parse_css {
  my ($self, $str, $substash, $symbols) = @_;
  $str =~ s{/[*].*?[*]/}{}smxg;
  my $groups = [$str =~ /[^\n]+{.*?}/smxg];

  for my $g (@{$groups}) {
    my ($tokens, $block) = $g =~ m/(.*){(.*)}/smxg;
    $tokens =~ s/^\s+//smx;
    $tokens =~ s/\s+$//smx;

    $substash->{$tokens} ||= {};

    my $kvs = [split /;/smx, $block];

    for my $kv (@{$kvs}) {
      $kv =~ s/^\s+//smx;
      $kv =~ s/\s+$//smx;

      if(!$kv) {
        next;
      }

      my ($key, $value) = split /:/smx, $kv;
      $key   =~ s/^\s+//smx;
      $key   =~ s/\s+$//smx;
      $value =~ s/^\s+//smx;
      $value =~ s/\s+$//smx;

      $substash->{$tokens}->{$key} = $value;
    }
  }
  return 1;
}

sub _stash2css {
  my ($self, $stash, $symbols) = @_;
  my $groups  = [];
  my $delayed = [];

  for my $k (keys %{$stash}) {
#    if($k =~ /^__/smx) {
#      next;
#    }

    my $str .= "$k {\n";
    for my $attr (sort keys %{$stash->{$k}}) {
      my $val = $stash->{$k}->{$attr};

#      carp qq[___ATTR=$attr val=$val];
      if($attr =~ /^[+]/smx) {
	$attr=q[];
      }

      if($attr =~ /:$/smx) {
	my $rattr = $attr;
	$rattr    =~ s/:$//smx;
	for my $k2 (sort keys %{$val}) {
	  $str .= "  $rattr-$k2: @{[$self->_expr($stash, $symbols, $val->{$k2})]};\n";
	}
	next;
      }

      if(ref $val) {
	my $rattr = $k . ($attr ? " $attr":q[]);
	push @{$delayed}, $self->_stash2css({$rattr => $val}, $symbols);
	next;
      }

      $str .= "  $attr: @{[$self->_expr($stash, $symbols, $val)]};\n";
    }
    $str .= "}\n";
    if($str !~ /[{]\s*[}]/smx) {
      push @{$groups}, $str;
    }
    push @{$groups}, @{$delayed};
  }

  return join "\n", @{$groups};
}

sub _expr {
  my ($self, $stash, $symbols, $expr) = @_;
  my $vars = $symbols->{variables} || {};

#carp qq[_EXPR VARS = ].Dumper($vars);
  $expr =~ s/!(\S+)/{$vars->{$1}||"!$1"}/smxeg;
  $expr =~ s/[#](.)(.)(.)(\b)/#${1}${1}${2}${2}${3}${3}$4/smxgi;

  my @parts = split /\s+/smx, $expr;

  Readonly::Scalar my $binary_op_parts => 3;
  if(scalar @parts == $binary_op_parts) {
    return Text::Sass::Expr->expr(@parts);
  }

  return $expr;
}

sub _stash2sass {
  my ($self, $stash, $symbols) = @_;
  my $groups = [];

  for my $k (keys %{$stash}) {
#    if($k =~ /^__/smx) {
#      next;
#    }

    my $str .= "$k\n";
    for my $attr (sort keys %{$stash->{$k}}) {
      my $val = $stash->{$k}->{$attr};
      $str .= "  $attr: $val\n";
    }
    push @{$groups}, $str;
  }

  return join "\n", @{$groups};
}

1;
__END__

=head1 NAME

Text::Sass

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - Constructor - nothing special

  my $oSass = Text::Sass->new;

=head2 css2sass - Translate CSS to Sass

  my $sSass = $oSass->css2sass($sCSS);

=head2 sass2css - Translate Sass to CSS

  my $sCSS = $oSass->sass2css($sSass);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Carp

=item English

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

See README

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
