package Games::LMSolve::Tilt::Single;

use strict;
use warnings;

use Games::LMSolve::Tilt::Base;

use Games::LMSolve::Input;

use vars qw(@ISA);

@ISA=qw(Games::LMSolve::Tilt::Base);

sub input_board
{
    my $self = shift;
    my $filename = shift;
    
    my $spec = 
    {
        'dims' => { 'type' => "xy(integer)", 'required' => 1 },
        'start' => { 'type' => "xy(integer)", 'required' => 1 },
        'goal' => {'type' => "xy(integer)", 'required' => 1 },
        'layout' => { 'type' => "layout", 'required' => 1},
    };

    my $input_obj = Games::LMSolve::Input->new();

    my $input_fields = $input_obj->input_board($filename, $spec);

    my ($width, $height) = @{$input_fields->{'dims'}->{'value'}}{'x','y'};
    my ($start_x, $start_y) = @{$input_fields->{'start'}->{'value'}}{'x','y'};
    my ($goal_x, $goal_y) = @{$input_fields->{'goal'}->{'value'}}{'x','y'};
    
    if (($start_x >= $width) || ($start_y >= $height))
    {
        die "The starting position is out of bounds of the board in file \"$filename\"!\n";        
    }

    if (($goal_x >= $width) || ($goal_y >= $height))
    {
        die "The goal position is out of bounds of the board in file \"$filename\"!\n";        
    }

    my ($horiz_walls, $vert_walls) = 
        $input_obj->input_horiz_vert_walls_layout($width, $height, $input_fields->{'layout'});

    $self->{'width'} = $width;
    $self->{'height'} = $height;
    $self->{'goal_x'} = $goal_x;
    $self->{'goal_y'} = $goal_y;
    $self->{'horiz_walls'} = $horiz_walls;
    $self->{'vert_walls'} = $vert_walls;
    
    return [ $start_x, $start_y ];    
}

sub pack_state
{
    my $self = shift;
    my $state_vector = shift;

    return pack("cc", @$state_vector);
}

sub unpack_state
{
    my $self = shift;
    my $state = shift;
    return [ unpack("cc", $state) ];
}

sub display_state
{
    my $self = shift;
    my $state = shift;
    my ($x, $y) = (map { $_ + 1} @{$self->unpack_state($state)});
    return sprintf("($x,$y)");
}

sub check_if_final_state
{
    my $self = shift;

    my $coords = shift;

    return (($coords->[0] == $self->{'goal_x'}) && ($coords->[1] == $self->{'goal_y'}));
}

sub enumerate_moves
{
    my $self = shift;
    my $coords = shift;

    return (qw(u d l r));
}

sub perform_move
{
    my $self = shift;

    my $coords = shift;
    my $move = shift;

    my ($new_coords, $intermediate_states) = 
        $self->move_ball_to_end($coords, $move);
    
    return $new_coords;
}

1;


=head1 NAME

Games::LMSolve::Tilt::Single - driver for solving the single-goal tilt mazes

=head1 SYNOPSIS

NA - should not be used directly.

=head1 METHODS

=head2 $self->input_board()

Overrided.

=head2 $self->pack_state()

Overrided.

=head2 $self->unpack_state()

Overrided.

=head2 $self->display_state()

Overrided.

=head2 $self->check_if_unsolvable()

Overrided.

=head2 $self->check_if_final_state()

Overrided.

=head2 $self->enumerate_moves()

Overrided.

=head2 $self->perform_move()

Overrided.

=head1 SEE ALSO

L<Games::LMSolve::Base>.

For more about single-goal tilt mazes see:

L<http://www.clickmazes.com/newtilt/ixtilt2d.htm>

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/>

=cut

