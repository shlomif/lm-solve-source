package Games::LMSolve::Registry;

use strict;
use warnings;

=head1 NAME

Games::LMSolve::Registry - the registry of all LM-Solve drivers.

=head1 DESCRIPTION

This is a registry of all LM-Solve drivers.

=head1 METHODS 
=cut

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

=head2 $self->register_all_solvers()

Register all the solvers.

=cut

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

=head1 SEE ALSO

L<Games::LMSolve>

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/>

