use strict;
use warnings;
use Text::Sass;
use Test::More tests => 2;

{
  my $sass_str = <<EOT;
=table-scaffolding
  th
    text-align: center
    font-weight: bold

#data
  +table-scaffolding
EOT

  my $css_str = <<EOT;
#data th {
  font-weight: bold;
  text-align: center;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'static mixin');
}

{
  my $sass_str = <<EOT;
=macro(!dist)
  margin-left = !dist
  float: left

#data
  +macro(10px)
EOT

  my $css_str = <<EOT;
#data {
  float: left;
  margin-left: 10px;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'dynamic mixin, one variable');
}

{
  my $sass_str = <<EOT;
=table-scaffolding
  th
    text-align: center
    font-weight: bold
  td, th
    padding: 2px

=left(!dist)
  float: left
  margin-left = !dist

#data
  +left(10px)
  +table-scaffolding
EOT

  my $css_str = <<EOT;
#data {
  float: left;
  margin-left: 10px;
}
#data th {
  text-align: center;
  font-weight: bold;
}
#data td, #data th {
  padding: 2px;
}
EOT

  my $sass = Text::Sass->new();
#  is($sass->sass2css($sass_str), $css_str, 'complex mixin, static + dynamic');
}
