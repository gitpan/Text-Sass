use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  our $TODO = "Parent ref with commas not working";
  my $css  = <<EOT;
header {
  background: #FFFFFF;
}

#header .error {
  color: #FF0000;
}

#header a, p {
  text-decoration: none;
}

#header a:hover, #header p:hover {
  text-decoration: underline;
}
EOT

  my $sass = <<EOT;
#header
  background: #FFFFFF
  /* -or-  :background #FFFFFF

  .error
    color: #FF0000

  a, p
    text-decoration: none
    &:hover
      text-decoration: underline
EOT

  SKIP: {
      skip $TODO, 1;

      my $ts = Text::Sass->new();
      is($ts->sass2css($sass), $css, "sass to css conversion ok");
    }
}
