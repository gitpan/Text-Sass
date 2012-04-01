use strict;
use warnings;
use Text::Sass '0.94';
use Test::More tests => 2;

{
  my $css  = <<EOT;
a {
  font-weight: bold;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}
EOT

  my $scss = <<EOT;
a {
  font-weight: bold;
  text-decoration: none;
  &:hover { text-decoration: underline; }
}
EOT

  my $ts = Text::Sass->new();
  
  is($ts->scss2css($scss), $css, "simple parent reference");
}

{
  my $css  = <<EOT;
a {
  font-weight: bold;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

body.firefox a {
  font-weight: normal;
}
EOT

  my $scss = <<EOT;
a {
  font-weight: bold;
  text-decoration: none;
  &:hover { text-decoration: underline; }
  body.firefox & { font-weight: normal; }
}
EOT

  my $ts = Text::Sass->new();
  
  is($ts->scss2css($scss), $css, "complex parent reference");
}
