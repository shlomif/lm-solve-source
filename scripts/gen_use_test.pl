#!/usr/bin/perl -w

use strict;

my @modules = 
    (
        (map 
            { 
                "Games::LMSolve::$_" 
            } 
            qw(Numbers Base Plank::Base Plank::Hex Alice),
            qw(Tilt::Base Tilt::Single Tilt::Multi Tilt::RedBlue),
            qw(Input Registry)
        ),
        "Games::LMSolve"
    );

my $num_modules = scalar(@modules);

open O, ">t/00use.t";
print O <<"EOF" ;
#!/usr/bin/perl -w

use strict;

use Test::More tests => $num_modules;

BEGIN 
{
EOF

foreach (@modules)
{
    print O "use_ok(\"$_\");\n";
}

print O "}\n";

close(O);
