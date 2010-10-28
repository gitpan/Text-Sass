use strict;
use warnings;
use Test::More tests => 1;
use Text::Sass;

my $sass = <<EOT;
#header
  background: #FFFFFF
  /* -or-  :background #FFFFFF
  .error
    color: #FF0000
  a
    text-decoration: none
    &:hover
      text-decoration: underline
EOT

my $css = <<EOT;
#header {
  background: #FFFFFF;
}

#header .error {
  color: #FF0000;
}

#header a {
  text-decoration: none;
}

#header a:hover {
  text-decoration: underline;
}
EOT

my $ts = Text::Sass->new;
is($ts->sass2css($sass), $css, 'wikipedia example 1');
