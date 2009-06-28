package Games::LMSolve::Tilt::Base;

use strict;
use warnings;

use vars qw(@ISA);

use Games::LMSolve::Base;

@ISA=qw(Games::LMSolve::Base);

# x - the x step
# y - the y step
# w - which wall
my %moves_specs =
(
    'u' => { 'x' => 0, 'y' => -1, 'w' => 'h'},
    'd' => { 'x' => 0, 'y' => 1, 'w' => 'h'},
    'l' => { 'x' => -1, 'y' => 0, 'w' => 'v'},
    'r' => { 'x' => 1, 'y' => 0, 'w' => 'v'},
);

# This function moves the ball to the end.
# It returns the new position as well as all the intermediate positions.
sub move_ball_to_end
{
    my $self = shift;

    my $coords = shift;
    my $move = shift;

    my ($x,$y) = @$coords;
    my @intermediate_coords = ();

    if (!exists($moves_specs{$move}))
    {
        die "Unknown move \"$move\"!";
    }

    my $horiz_walls = $self->{'horiz_walls'};
    my $vert_walls = $self->{'vert_walls'};

    my ($x_dir, $y_dir, $which_wall) = @{$moves_specs{$move}}{'x','y','w'};

    push @intermediate_coords, [$x, $y];
    while (! (($which_wall eq 'v') ?
        ($vert_walls->[$y]->[$x+(($x_dir<0)?0:1)]) :
        ($horiz_walls->[$y + (($y_dir<0)?0:1)]->[$x])
        ))
    {
        $x += $x_dir;
        $y += $y_dir;
        push @intermediate_coords, [$x, $y];
    }

    return ([$x,$y], \@intermediate_coords);
}

1;


=head1 NAME

Games::LMSolve::Tilt::Base - base class for the tilt mazes' drivers.

=head1 SYNOPSIS

NA - should not be used directly.

=head1 METHODS

=head2 $self->move_ball_to_end()

Moves the ball to the end.

=head1 SEE ALSO

L<Games::LMSolve::Base>.

For more about tilt mazes see:

http://www.clickmazes.com/indext.htm

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/>

=cut

