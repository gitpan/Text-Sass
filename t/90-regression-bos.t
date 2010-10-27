use strict;
use warnings;
use Text::Sass '0.5';
use Test::More tests => 4;

{
  my $css  = <<EOT;
h1 {
  color: #333;
}
EOT

  my $sass = <<EOT;
h1
  color: #333
EOT

  my $ts = Text::Sass->new();

  is($ts->css2sass($css), $sass, "css to sass conversion ok");
  is($ts->sass2css($sass), $css, "sass to css conversion ok");
}

{
  my $css  = <<EOT;
h1, h2 {
  color: #333;
}
EOT

  my $sass = <<EOT;
h1, h2
  color: #333
EOT

  my $ts = Text::Sass->new();

#  $Text::Sass::DEBUG = 1;

  is($ts->css2sass($css), $sass, "css to sass conversion ok");
  is($ts->sass2css($sass), $css, "sass to css conversion ok");
}
