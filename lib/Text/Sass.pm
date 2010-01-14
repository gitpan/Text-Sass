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

our $VERSION = q[0.3];

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

  my $stash = {};
  $self->_parse_css($str, $stash);
  return $self->_stash2sass($stash);
}

sub sass2css {
  my ($self, $str) = @_;

  if(!ref $self) {
    $self = $self->new;
  }

  my $stash = {};
  $self->_parse_sass($str, $stash);
#  use Data::Dumper; carp Dumper($stash);
  return $self->_stash2css($stash);
}

sub _parse_sass {
  my ($self, $str, $substash) = @_;

  my $groups = [split /\n\s*?\n/smx, $str];

  for my $g (@{$groups}) {
    my @lines = split /\n/smx, $g;

    while(my $line = shift @lines) {
      #########
      # !x = y
      #
      $line =~ s{^!(\S+)\s*=\s*(.*)$}{
        $substash->{__variables}->{$1} = $2;
        q[];
      }smxegi;

      #########
      # .class
      # #id
      # element
      # <following content>
      #
      $line =~ s{^([.#]?\S+)$}{
        my $remaining = join "\n", @lines;
        @lines = ();
        $substash->{$1} = {};
        $self->_parse_sass($remaining, $substash->{$1});
        q[];
      }smxegi;

      #########
      # static & dynamic attr: value
      #
      $line =~ s{^(\S+)\s*[:=]\s*(.*)$}{
        $substash->{$1} = $2;
        q[];
      }smxegi;

      #########
      #   <indented sub-content>
      #
      $line =~ s{^[ ][ ](.*?)$}{
        my $remaining = join "\n", $1, @lines;
        $self->_parse_sass($remaining, $substash);
        @lines = ();
        q[];
      }smxegi;

      #########
      # // comments
      #
      $line =~ s{\s*//(.*)}{
        $substash->{__comments} ||= [];
        push @{$substash->{__comments}}, $1;
        q[];
      }smxegi;
    }
  }

  return 1;
}

sub _parse_css {
  my ($self, $str, $substash) = @_;
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
  my ($self, $stash) = @_;
  my $groups  = [];
  my $delayed = [];

  for my $k (keys %{$stash}) {
    if($k =~ /^__/smx) {
      next;
    }

    my $str .= "$k {\n";
    for my $attr (sort keys %{$stash->{$k}}) {
      my $val = $stash->{$k}->{$attr};

      if($attr =~ /:$/smx) {
	my $rattr = $attr;
	$rattr    =~ s/:$//smx;
	for my $k2 (sort keys %{$val}) {
	  $str .= "  $rattr-$k2: @{[$self->_expr($stash, $val->{$k2})]};\n";
	}
	next;
      }

      if(ref $val) {
	push @{$delayed}, $self->_stash2css({"$k $attr" => $val});
	next;
      }

      $str .= "  $attr: @{[$self->_expr($stash, $val)]};\n";
    }
    $str .= "}\n";
    push @{$groups}, $str;
    push @{$groups}, @{$delayed};
  }

  return join "\n", @{$groups};
}

sub _expr {
  my ($self, $stash, $expr) = @_;
  my $vars = $stash->{__variables} || {};

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
  my ($self, $stash) = @_;
  my $groups = [];

  for my $k (keys %{$stash}) {
    if($k =~ /^__/smx) {
      next;
    }

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
