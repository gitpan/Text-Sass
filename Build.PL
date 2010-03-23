#########
# Author:        rmp
# Last Modified: $Date$
# Id:            $Id$
# Source:        $Source$
# $HeadURL$
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
							 'Carp'                        => '1.04',
							 'English'                     => '1.03',
							 'Readonly'                    => '1.03',
							 'strict'                      => '1.03',
							 'warnings'                    => '1.05',
							},
				 recommends          => {
							},
				 build_requires      => {
							 'Test::More'              => '0.8',
							},
				 build_recommends    => {
							 'Test::Distribution'      => '2.00',
							 'Test::Perl::Critic'      => '1.01',
							},
				 sign                => 1,
				);

$builder->create_build_script();
