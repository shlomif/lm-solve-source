package Games::LMSolve::Registry;

use strict;

use Games::LMSolve;

use vars qw(@ISA);

@ISA=qw(Games::LMSolve);

use Games::LMSolve::Alice;
use Games::LMSolve::Minotaur;
use Games::LMSolve::Numbers;
use Games::LMSolve::Plank::Base;
use Games::LMSolve::Tilt::Single;
use Games::LMSolve::Tilt::Multi;
use Games::LMSolve::Tilt::RedBlue;
use Games::LMSolve::Plank::Hex;

sub register_all_solvers
{
    my $self = shift;
    $self->register_solvers(
        {
            'alice' => "Games::LMSolve::Alice",
            'minotaur' => "Games::LMSolve::Minotaur",
            'numbers' => "Games::LMSolve::Numbers",
            'plank' => "Games::LMSolve::Plank::Base",
            'hex_plank' => "Games::LMSolve::Plank::Hex",
            'tilt_single' => "Games::LMSolve::Tilt::Single",
            'tilt_multi' => "Games::LMSolve::Tilt::Multi",
            'tilt_rb' => "Games::LMSolve::Tilt::RedBlue",
            'tilt_puzzle' => "Games::LMSolve::Tilt::RedBlue",
        }
    );

    $self->set_default_variant("minotaur");

    return 0;
}

1;


