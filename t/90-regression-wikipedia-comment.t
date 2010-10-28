use strict;
use warnings;
use Test::More tests => 2;
use Text::Sass;

{
  my $sass = <<EOT;
#header
  background: #FFFFFF
  /* -or-  :background #AAAAAA

#footer
  color: #000
EOT

  my $css = <<EOT;
#header {
  background: #FFFFFF;
}

#footer {
  color: #000;
}
EOT

  my $ts = Text::Sass->new;
  is($ts->sass2css($sass), $css, 'wikipedia example unterminated /* comment');
}

{
  my $sass = <<EOT;
#header
  background: #FFFFFF
  /* -or-  :background #AAAAAA

#footer
  /* comment */ color: #000
EOT

  my $css = <<EOT;
#header {
  background: #FFFFFF;
}

#footer {
  color: #000;
}
EOT

  my $ts = Text::Sass->new;
  is($ts->sass2css($sass), $css, 'wikipedia example terminated /* comment */');
}
