use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  my $sass_str = <<"EOT";
!blue = #3bbfce
!margin = 16px

.content_navigation
  border-color = !blue
  color = !blue - #111

.border
  padding = !margin / 2
  margin = !margin / 2
  border-color = !blue
EOT

  my $css_str = <<"EOT";
.border {
  border-color: #3bbfce;
  margin: 8px;
  padding: 8px;
}

.content_navigation {
  border-color: #3bbfce;
  color: #2aaebd;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass2css');
}
