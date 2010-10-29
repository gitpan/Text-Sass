#########
# Author:        rmp
# Last Modified: $Date: 2010-10-29 12:45:25 +0100 (Fri, 29 Oct 2010) $
# Id:            $Id: 00-critic.t 37 2010-10-29 11:45:25Z zerojinx $
# Source:        $Source$
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/00-critic.t $
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = 1;

if ( not $ENV{TEST_AUTHOR} ) {
  my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
  plan( skip_all => $msg );
}

eval {
  require Test::Perl::Critic;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Perl::Critic not installed';

} else {
  Test::Perl::Critic->import(
			     -severity => 1,
			     -exclude => [qw(CodeLayout::RequireTidyCode
					     ValuesAndExpressions::ProhibitImplicitNewlines
					     NamingConventions::Capitalization
					     PodSpelling
 					     ValuesAndExpressions::RequireConstantVersion
					     ControlStructures::ProhibitDeepNests)],
			    );
  all_critic_ok();
}

1;
