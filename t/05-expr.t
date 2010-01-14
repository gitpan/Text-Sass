use strict;
use warnings;
use Test::More;

our @CONVS = (
	      [1, "cm", 10,   "mm"],
	      [1, 'in', 2.54, 'cm'],
	      [1, 'in', 25.4, 'mm'],
	     );
our @EXPRS = (
	      ["10cm - 1cm", "9cm"],
	      ["10cm - 1mm", "9.9cm"],
	      ["1in / 10cm", "0.254in"],
	      ["#3bbfce - #111111", "#2aaebd"],
	     );

plan tests => 7 + scalar @EXPRS;

my $pkg = 'Text::Sass::Expr';
use_ok($pkg);

{
  is_deeply($pkg->units('10px'), [10, 'px'], '10px units');
}

{
  is_deeply($pkg->units('2'), [2, ''], '2 units');
}

{
  is_deeply($pkg->units('#efefff'), [[239,239,255], '#'], '#efefff units');
}

for my $set (@CONVS) {
  is($pkg->convert($set->[0], $set->[1], $set->[3]), $set->[2], "$set->[0]$set->[1] = $set->[2]$set->[3]");
}

for my $set (@EXPRS) {
  my @bits = split /\s/smx, $set->[0];
  is($pkg->expr(@bits), $set->[1], "$set->[0] = $set->[1]");
}
