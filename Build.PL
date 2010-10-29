#########
# Author:        rmp
# Last Modified: $Date: 2010-10-29 12:45:25 +0100 (Fri, 29 Oct 2010) $
# Id:            $Id: Build.PL 37 2010-10-29 11:45:25Z zerojinx $
# Source:        $Source$
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/Build.PL $
#
use strict;
use warnings;
use Module::Build;
use lib qw(lib);

my $builder = Module::Build->new(
				 module_name         => 'Text-Sass',
				 dist_author         => 'Roger Pettett <rmp@psyphi.net>',
				 dist_version_from   => 'lib/Text/Sass.pm',
				 dist_abstract       => q[Text-Sass - Perl implementation of http://sass-lang.com/],
				 license             => 'perl',
				 requires            => {
							 'Carp'                    => '1.04',
							 'English'                 => '1.04',
							 'Readonly'                => '1.03',
							 'strict'                  => '1.03',
							 'warnings'                => '1.05',
							},
				 recommends          => {
							 'Data::Dumper'            => '2.125',
							},
				 build_requires      => {
							 'Test::More'              => '0.8',
							 'Try::Tiny'               => '0.06',
							},
				 build_recommends    => {
							 'Test::Distribution'      => '2.00',
							 'Test::Perl::Critic'      => '1.01',
							},
				 script_files        => qw(bin/sass2css.pl),
#				 sign                => 1,
				);

$builder->create_build_script();
