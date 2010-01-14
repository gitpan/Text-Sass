use strict;
use warnings;
use Text::Sass;
use Test::More tests => 2;

{
  my $sass_str = <<"EOT";
table.hl
  margin: 2em 0
  td.ln
    text-align: right
EOT

  my $css_str = <<"EOT";
table.hl {
  margin: 2em 0;
}

table.hl td.ln {
  text-align: right;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass2css');
}

{
  my $sass_str = <<"EOT";
li
  font:
    family: serif
    weight: bold
    size: 1.2em
EOT

  my $css_str = <<"EOT";
li {
  font-family: serif;
  font-size: 1.2em;
  font-weight: bold;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass2css');
}
