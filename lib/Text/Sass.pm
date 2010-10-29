#########
# Author:        rmp
# Last Modified: $Date: 2010-10-29 12:52:18 +0100 (Fri, 29 Oct 2010) $
# Id:            $Id: Sass.pm 40 2010-10-29 11:52:18Z zerojinx $
# Source:        $Source$
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/lib/Text/Sass.pm $
#
# Note to reader:
# Recursive regex processing can be very bad for your health.
# Sass & SCSS are both pretty cool. This module is not.
#
package Text::Sass;
use strict;
use warnings;
use Carp;
use English qw(-no_match_vars);
use Text::Sass::Expr;
use Data::Dumper;

our $VERSION = q[0.8.1];
our $DEBUG   = 0;

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
  my $stash   = [];
  my $chain   = [];
  $self->{_sass_indent} = 0;
  $self->_parse_sass($str, $stash, $symbols, $chain);
#  use Data::Dumper; carp 'STASH ' . Dumper($stash);
#  use Data::Dumper; carp 'SYMBOLS ' . Dumper($symbols);
  return $self->_stash2css($stash, $symbols);
}

sub _parse_sass {
  my ($self, $str, $substash, $symbols, $chain) = @_;
  $DEBUG and print {*STDERR} q[=]x30, q[begin _parse_sass], q[=]x30, "\n";

  #########
  # insert blank links after code2:
  # code1
  #  code2
  # code3
  #  code4
  #
  $str =~ s/\n(\S)/\n\n$1/smxg;

  #########
  # strip blank lines from:
  # <blank line>
  #   code
  #
  $str =~ s/^\s*\n(\s+)/$1/smxg;

  my $groups = [split /\n\s*?\n/smx, $str];
  for my $g (@{$groups}) {
    my @lines = split /\n/smx, $g;

    while(my $line = shift @lines) {
      #########
      # /* comment */
      # /* comment
      #
      $line =~ s{/[*].*?[*]/\s*}{}smx;
      $line =~ s{/[*].*$}{}smx;

      #########
      # !x = y   variable declarations
      # BOS: Is this deprecated?
      #
      $line =~ s{^\!(\S+)\s*=\s*(.*?)$}{
        $symbols->{variables}->{$1} = $2;
        $DEBUG and carp qq[VARIABLE $1 = $2];
       q[];
      }smxegi;

      #########
      # $x = y   variable declarations
      #
      $line =~ s{^\$(\S+)\s*:\s*(.*?)$}{
        $symbols->{variables}->{$1} = $2;
        $DEBUG and carp qq[VARIABLE $1 = $2];
       q[];
      }smxegi;

      #########
      # =x              |      =x(!var)
      #   bla           |        bla
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
        $DEBUG and carp qq[MIXIN $func];
        q[];
      }smxegi;

      #########
      # @include
      #
      # mixin usage
      #
      $line =~ s{^\@include\s*(.*?)(?:[(](.*?)[)])?$}{
        my ($func, $argstr) = ($1, $2);
        my $mixin_str  = $symbols->{mixins}->{$func};

        my $subsymbols = $symbols; # todo: correct scoping - is better as {%{$symbols}}
        my $values     = $argstr ? [split /\s*,\s*/smx, $argstr] : [];
        my ($varstr)   = $mixin_str =~ /^.*?[(](.*?)[)]/smx;
        my $vars       = $varstr ? [split /\s*,\s*/smx, $varstr] : [];

        for my $var (@{$vars}) {
          $var =~ s/^[\!\$]//smx;
          $subsymbols->{variables}->{$var} = shift @{$values};
        }

        $mixin_str    =~ s/^.*?\n//smx;
        my $result    = [];

        $self->_parse_sass($mixin_str, $result, $subsymbols, [@{$chain}]);
        push @$substash, {"+$func" => $result};

        $DEBUG and carp qq[DYNAMIC MIXIN $func];
        q[];
      }smxegi;

      #########
      # @mixin name
      #   bla
      #
      # mixin declaration
      #
      $line =~ s{^\@mixin\s+(.*?)$}{
        my $mixin_stash = {};
        my $remaining   = join "\n", @lines;
        @lines          = ();
        my $proto       = $1;
        my ($func)      = $1 =~ /^([^(]+)/smx;

        #########
        # mixins are interpolated later, so we just store the string here
        #
        $symbols->{mixins}->{$func} = "$proto\n$remaining\n";
        $DEBUG and carp qq[MIXIN $func];
        q[];
      }smxegi;

      #########
      # static +mixin
      #
      $line =~ s{^[+]([^(]+)$}{
        my $func      = $1;
        my $mixin_str = $symbols->{mixins}->{$func};
        $mixin_str    =~ s/^.*?\n//smx;
        my $result    = [];

        $self->_parse_sass($mixin_str, $result, $symbols, [@{$chain}]);

        my $mixin_tag = (keys %{$result->[0]})[0];
        push @$substash, {$mixin_tag => (values %{$result->[0]})[0]};
        $DEBUG and carp qq[STATIC MIXIN $func / $mixin_tag];
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

        for my $var (@{$vars}) {
          $var =~ s/^[\!\$]//smx;
          $subsymbols->{variables}->{$var} = shift @{$values};
        }

        $mixin_str    =~ s/^.*?\n//smx;
        my $result    = [];

        $self->_parse_sass($mixin_str, $result, $subsymbols, [@{$chain}]);
        push @$substash, {"+$func" => $result};

        $DEBUG and carp qq[DYNAMIC MIXIN $func];
        q[];
      }smxegi;

      #########
      # parent ref
      #
      # tag
      #   attribute: value
      #   &:pseudoclass
      #     attribute: value2
      #
      $line =~ s{^(&\s*[:=]\s*.*?)$}{
        my $pseudo = $1;
        $DEBUG and carp qq[PARENT REF: $pseudo CHAIN=@{$chain}];
        my $remaining = join "\n", @lines;
        @lines        = ();
        my $newkey    = join q[ ], @{$chain};
        $pseudo       =~ s/&/&$newkey/smx;
        my $subsubstash = [];
        $self->_parse_sass($remaining, $subsubstash, $symbols, ['TBD']);
        push @$substash, {$pseudo => $subsubstash};
        q[];
      }smxegi;

      #########
      # static & dynamic attr: value
      # color: #aaa
      #
      $line =~ s{^(\S+)\s*[:=]\s*(.*?)$}{
        my $key = $1;
        my $val = $2;

        $DEBUG and carp qq[ATTR $key = $val];

        if($val =~ /^\s*$/smx) {
          my $remaining = join "\n", @lines;
          @lines        = ();
          my $ssubstash = [];
          $self->_parse_sass($remaining, $ssubstash, $symbols, [@{$chain}]);
          push @$substash, { "$key:" => $ssubstash };
        } else {
          push @$substash, { $key => $val };
        }
        q[];
      }smxegi;

      #########
      #   <x-space indented sub-content>
      #
      if ($line =~ /^([ ]+)(\S.*)$/smx) {
        my $indent = $1;
        # Indented
        if (!$self->{_sass_indent}) {
          $self->{_sass_indent} = length $1;
        }

        if ($line =~ /^[ ]{$self->{_sass_indent}}(\S.*)$/smx) {
          my $process = [];
          while (my $l = shift @lines) {
            if($l =~ /^[ ]{$self->{_sass_indent}}(.*)$/smx) {
              push @{$process}, $1;
            } elsif ($l !~ /^\s*$/xms) {
              #########
              # put it back where it came from
              #
              unshift @lines, $l;
              last;
            }
          }
          my $remaining = join "\n", $1, @{$process};

          $DEBUG and carp qq[INDENTED $line CALLING DOWN REMAINING=$remaining ].Dumper($substash);
          $self->_parse_sass($remaining, $substash, $symbols, [@{$chain}]);
          $line = q[];
        }
        else {
          croak 'Illegal ident '.length($indent).' we\'re using '.$self->{_sass_indent} . " ($line)";
        }
      }

      #########
      # .class
      # #id
      # element
      # element2, element2
      #   <following content>
      #
      $line =~ s{^(\S+.*?)$}{
        my $one = $1;
        $one    =~ s/\s+/ /smxg;

        my $remaining     = join "\n", @lines;
        @lines            = ();
        my $subsubstash   = [];

        $DEBUG and carp qq[ELEMENT $one descending with REMAINING=$remaining];
        $DEBUG and carp Dumper($substash);
        $self->_parse_sass($remaining, $subsubstash, $symbols, [@{$chain}, $one]);
        push @$substash, { $one => $subsubstash };
        $DEBUG and carp qq[ELEMENT $one returned];
        $DEBUG and carp Dumper($substash);
        q[];
      }smxegi;


      $DEBUG and $line and carp qq[REMAINING $line];
    }
  }

  $DEBUG and print {*STDERR} q[=]x30, q[ end _parse_sass ], q[=]x30, "\n";

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

  for my $stash_line (@{$stash}) {
    for my $k (keys %{$stash_line}) {
      my $vk = $k;
      $vk    =~ s/\s+/ /smx;

      if($k =~ /&/smx) {
	($vk) = $k =~ /&(.*)$/smx;
	$stash_line->{$vk} = $stash_line->{$k};
	delete $stash_line->{$k};
	$k = $vk;
      }

      my $str .= "$vk {\n";
      if(!ref $stash_line->{$k}) {
	$str .= sprintf q[ %s: %s], $vk, $stash_line->{$k};

      } else {
	for my $attr_line (@{$stash_line->{$k}}) {
	  for my $attr (sort keys %{$attr_line}) {
	    my $val = $attr_line->{$attr};

	    if($attr =~ /^[+]/smx) {
	      $attr = q[];
	    }

	    if($attr =~ /:$/smx) {
	      #########
	      # font:
	      #   family: foo;
	      #   size: bar;
	      #
	      my $rattr = $attr;
	      $rattr    =~ s/:$//smx;
	      for my $val_line (@{$val}) {
		for my $k2 (sort keys %{$val_line}) {
		  $str .= sprintf qq[  %s-%s: %s;\n], $rattr, $k2, $self->_expr($stash, $symbols, $val_line->{$k2});
		}
	      }
	      next;
	    }
	    if(ref $val) {
	      if($attr) {
		$attr = sprintf q[ %s], $attr;
	      }

	      my $rattr = $k . ($attr ? $attr : q[]);

	      if($k =~ /,/smx) {
		$rattr = join q[, ], map { "$_$attr" } split /[,\s]+/smx, $k;
	      }

	      if($attr =~ /,/smx) {
		$attr =~ s/^\s//smx;
		$rattr = join q[, ], map { "$k $_" } split /[,\s]+/smx, $attr;
	      }
	      # TODO: What if both have ,?

	      push @{$delayed}, $self->_stash2css([{$rattr => $val}], $symbols);
	      next;
	    }
	    $str .= sprintf qq[  %s: %s;\n], $attr, $self->_expr($stash, $symbols, $val);
	  }
	}
      }

      $str .= "}\n";
      if($str !~ /[{]\s*[}]/smx) {
	push @{$groups}, $str;
      }
      push @{$groups}, @{$delayed};
      $delayed = [];
    }
  }

  return join "\n", @{$groups};
}

sub _expr {
  my ($self, $stash, $symbols, $expr) = @_;
  my $vars = $symbols->{variables} || {};

  $expr =~ s/\!(\S+)/{$vars->{$1}||"\!$1"}/smxeg;
  $expr =~ s/\$(\S+)/{$vars->{$1}||"\$$1"}/smxeg;

  my @parts = split /\s+/smx, $expr;

  # BOS: Support for functions

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
    my $str .= "$k\n";

    for my $attr (sort keys %{$stash->{$k}}) {
      my $val = $stash->{$k}->{$attr};
      $str   .= sprintf qq[  %s: %s\n], $attr, $val;
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

$LastChangedRevision: 40 $

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

There is no support for colorfunctions. There is no support for extends.

=head1 BUGS AND LIMITATIONS

See README

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
