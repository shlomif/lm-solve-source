use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Games::LMSolve',
    'DISTNAME' => 'Games-LMSolve',
    'EXE_FILES' => ["lm-solve"],
    'VERSION_FROM' => 'lib/Games/LMSolve/Base.pm',
    );

use lib './lib';
require Games::LMSolve::Base;

my $version = $Games::LMSolve::Base::VERSION;
print "Generating the RPM SPEC file\n";
open I, "<lm-solve.spec.in";
open O, ">lm-solve.spec";
while (<I>)
{
    s!\[\[VERSION\]\]!$version!g;
    print O $_;
}
close(O);
close(I);

