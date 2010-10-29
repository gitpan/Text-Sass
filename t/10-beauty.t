use strict;
use warnings;
use Text::Sass;
use Test::More tests => 2;

my $sass_str = <<"EOT";
h1
  height: 118px
  margin-top: 1em

.tagline
  font-size: 26px
  text-align: right
EOT

my $css_str = <<"EOT";
h1 {
  height: 118px;
  margin-top: 1em;
}

.tagline {
  font-size: 26px;
  text-align: right;
}
EOT

{
  my $sass = Text::Sass->new();
  is($sass->css2sass($css_str), $sass_str, 'css2sass');
}

{
  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass2css');
}

