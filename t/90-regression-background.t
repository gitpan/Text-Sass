use strict;
use warnings;
use Text::Sass;
use Test::More tests => 2;

{
  my $scss = q[.x-panel-body { background: white url(/images/RegH_logo_RGB.gif) no-repeat; }];
  my $ts   = Text::Sass->new;
  is($ts->scss2css($scss), <<'EOT');
.x-panel-body {
  background: white url(/images/RegH_logo_RGB.gif) no-repeat;
}
EOT
}

{
  my $scss = q[.x-panel-body { background: url(/images/RegH_logo_RGB.gif) no-repeat; }];
  my $ts   = Text::Sass->new;
  is($ts->scss2css($scss), <<'EOT');
.x-panel-body {
  background: url(/images/RegH_logo_RGB.gif) no-repeat;
}
EOT
}
