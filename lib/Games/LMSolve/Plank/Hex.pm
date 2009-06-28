package Games::LMSolve::Plank::Hex;

use strict;
use warnings;

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

=head1 NAME

Games::LMSolve::Plank::Hex - driver for solving the hex plank puzzles

=head1 SYNOPSIS

NA - should not be used directly.

=head1 METHODS

=head2 $self->initialize()

Overrided.

=head1 SEE ALSO

L<Games::LMSolve::Base>.

For more about Plank puzzles see:

L<http://www.clickmazes.com/planks/ixplanks.htm> .

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/>

=cut

