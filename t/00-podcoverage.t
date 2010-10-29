#########
# Author:        rmp
# Last Modified: $Date: 2010-10-28 17:09:19 +0100 (Thu, 28 Oct 2010) $
# Id:            $Id: 00-podcoverage.t 19 2010-10-28 16:09:19Z zerojinx $
# Source:        $Source$
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/00-podcoverage.t $
#
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

all_pod_coverage_ok();
