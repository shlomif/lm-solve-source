package Games::LMSolve::Plank::Hex;

use strict;

use vars qw(@ISA);

use Games::LMSolve::Plank::Base;

@ISA=qw(Games::LMSolve::Plank::Base);

sub initialize
{
    my $self = shift;

    $self->SUPER::initialize(@_);

    $self->{'dirs'} = [qw(E W S N SE NW)];
}

1;

