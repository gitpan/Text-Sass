#########
# Author:        rmp
# Last Modified: $Date: 2010-10-28 17:09:19 +0100 (Thu, 28 Oct 2010) $
# Id:            $Id: 00-distribution.t 19 2010-10-28 16:09:19Z zerojinx $
# Source:        $Source$
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/00-distribution.t $
#
package distribution;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = 1;

eval {
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';
} else {
  Test::Distribution->import('not' => 'prereq'); # Having issues with Test::Dist seeing my PREREQ_PM :(
}

1;
