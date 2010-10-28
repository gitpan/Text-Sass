use strict;
use warnings;
use Test::More tests => 1;
use Text::Sass;

my $sass = <<EOT;
a
  text-decoration: none
  &:hover
    text-decoration: underline
EOT

my $css = <<EOT;
a {
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}
EOT

my $ts = Text::Sass->new;
is($ts->sass2css($sass), $css, 'wikipedia example parent "&" reference');
