use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  my $css  = <<EOT;
h1 {
  color: #333;
}

h2 {
  color: #555;
}
EOT

  my $sass = <<EOT;
h1
  color: #333
h2
  color: #555
EOT

  my $ts = Text::Sass->new();

  is($ts->sass2css($sass), $css, "sass to css conversion ok");
}
