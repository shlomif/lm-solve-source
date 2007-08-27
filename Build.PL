# This file is under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    module_name => "Games::LMSolve",
    build_requires =>
    {
        "Test::More" => 0,
    },
    requires => 
    {
    },
    dist_version_from => "lib/Games/LMSolve/Base.pm",
    license => "perl",
    create_makefile_pl => 'traditional',
    script_files => ["lm-solve"],
);

$build->create_build_script;

