
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Games::LMSolve',
    'DISTNAME' => 'Games-LMSolve',
    'EXE_FILES' => ["lm-solve"],
    'VERSION_FROM' => 'lib/Games/LMSolve/Base.pm',
    );
