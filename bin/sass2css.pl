#!/usr/bin/env perl
#########
# Author:        rmp
# Last Modified: $Date$
# Id:            $Id$
# Source:        $Source$
# $HeadURL$
#
use strict;
use warnings;
use lib qw(lib);
use Text::Sass;
use Carp;
use English qw(-no_match_vars);

our $VERSION = '1.00';

my $sass = Text::Sass->new();

if(!scalar @ARGV) {
  local $RS = undef;
  my $str   = <>;
  print $sass->sass2css($str) or croak $ERRNO;
}
