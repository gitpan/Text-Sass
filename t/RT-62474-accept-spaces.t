use strict;
use warnings;
use Text::Sass;
use Test::More tests => 3;
use Try::Tiny;

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

  is($ts->sass2css($sass), $css, "sass to css conversion ok");
}

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

  is($ts->sass2css($sass), $css, "sass to css conversion ok");
}

{
  my $sass = <<EOT;
h1
  color: #333
   display: inline
EOT

  my $ts = Text::Sass->new();
  
  try {
    diag $ts->sass2css($sass);
  }
  catch {
    ok(1, "dieing from illegal indent $_");
  }
  
}