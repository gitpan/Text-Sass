use strict;
use warnings;
use Test::More tests => 2;
use Text::Sass;

{
  my $sass = <<EOT;
#header
  background: #FFFFFF
  .error
    color: #FF0000
a
  text-decoration: none
  .hot
    color: red
EOT

  my $css = <<EOT;
#header {
  background: #FFFFFF;
}

#header .error {
  color: #FF0000;
}

a {
  text-decoration: none;
}

a .hot {
  color: red;
}
EOT

  my $ts = Text::Sass->new;
  is($ts->sass2css($sass), $css, 'without extra whitespace');
}

{
  my $sass = <<EOT;
#header
  background: #FFFFFF

  .error
    color: #FF0000

a
  text-decoration: none

  .hot
    color: red
EOT

  my $css = <<EOT;
#header {
  background: #FFFFFF;
}

#header .error {
  color: #FF0000;
}

a {
  text-decoration: none;
}

a .hot {
  color: red;
}
EOT

  my $ts = Text::Sass->new;
  is($ts->sass2css($sass), $css, 'with extra whitespace');
}
