use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  my $sass_str = <<EOT;
table
  display: none
  
  .hl
    display: block
    
    td
      color: #333
      
    #id
      margin: 2em 0
      
  #header
    position: absolute
EOT

  my $css_str = <<EOT;
table {
  display: none;
}

table .hl {
  display: block;
}

table .hl td {
  color: #333;
}

table .hl #id {
  margin: 2em 0;
}

table #header {
  position: absolute;
}
EOT

  my $sass = Text::Sass->new();
  is($sass->sass2css($sass_str), $css_str, 'sass2css');
}
