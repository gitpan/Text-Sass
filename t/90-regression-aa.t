use strict;
use warnings;
use Text::Sass '0.94';
use Test::More tests => 1;

{
  my $css  = <<EOT;
div.button {
  background: url(../img/button.gif) left top;
}
EOT

  my $scss = <<EOT;
div.button {
  background: url(../img/button.gif) left top;
}
EOT

  my $ts = Text::Sass->new();

  is($ts->scss2css($scss), $css, "scss to css conversion ok");
}
