package Games::LMSolve::Plank::Base;

use strict;

use vars qw(@ISA);

use Games::LMSolve::Base qw(%cell_dirs);

@ISA=qw(Games::LMSolve::Base);

use Games::LMSolve::Input;

sub initialize
{
    my $self = shift;

    $self->SUPER::initialize(@_);

    $self->{'dirs'} = [qw(E W S N)];
}

sub input_board
{
    my $self = shift;

    my $filename = shift;

    my $spec =
    {
        'dims' => { 'type' => "xy(integer)", 'required' => 1, },
        'planks' => { 'type' => "array(start_end(xy(integer)))", 
                      'required' => 1,
                    },
        'layout' => { 'type' => "layout", 'required' => 1,},        
    };

    my $input_obj = Games::LMSolve::Input->new();

    my $input_fields = $input_obj->input_board($filename, $spec);
    my ($width, $height) = @{$input_fields->{'dims'}->{'value'}}{'x','y'};
    my ($goal_x, $goal_y);

    if (scalar(@{$input_fields->{'layout'}->{'value'}}) < $height)
    {
        die "Incorrect number of lines in board layout (does not match dimensions";
    }
    my @board;
    my $lines = $input_fields->{'layout'}->{'value'};
    for(my $y=0;$y<$height;$y++)
    {
        my $l = [];
        if (length($lines->[$y]) < $width)
        {
            die "Too few characters in board layout in line No. " . ($input_fields->{'layout'}->{'line_num'}+$y+1);
        }
        my $x = 0;
        foreach my $c (split(//, $lines->[$y]))
        {
            push @$l, ($c ne " ");
            if ($c eq "G")
            {
                if (defined($goal_x))
                {
                    die "Goal was defined twice!";
                }
                ($goal_x, $goal_y) = ($x, $y);
            }
            $x++;
        }
        push @board, $l;        
    }
    if (!defined($goal_x))
    {
        die "The Goal was not defined in the layout";
    }
    
    my $planks_in = $input_fields->{'planks'}->{'value'};

    my @planks;

    my $get_plank = sub {
        my $p = shift;

        my ($start_x, $start_y) = ($p->{'start'}->{'x'},  $p->{'start'}->{'y'});
        my ($end_x, $end_y) = ($p->{'end'}->{'x'},  $p->{'end'}->{'y'});

        my $check_endpoints = sub {
            if (! $board[$start_y]->[$start_x])
            {
                die "Plank cannot be placed at point ($start_x,$start_y)!";
            }
            if (! $board[$end_y]->[$end_x])
            {
                die "Plank cannot be placed at point ($end_x,$end_y)!";
            }
        };        

        my $plank_str = "Plank ($start_x,$start_y) ==> ($end_x,$end_y)";

        if (($start_x >= $width) || ($end_x >= $width) || 
            ($start_y >= $height) || ($end_y >= $height))
        {
            die "$plank_str is out of the boundaries of the board";
        }

        if ($start_x == $end_x)
        {
            if ($start_y == $end_y)
            {
                die "$plank_str has zero length!";
            }
            $check_endpoints->();
            if ($start_y > $end_y)
            {
                ($start_y, $end_y) = ($end_y, $start_y);
            }
            foreach my $y (($start_y+1) .. ($end_y-1))
            {
                if ($board[$y]->[$start_x])
                {
                    die "$plank_str crosses logs!"
                }
            }
            return { 'len' => ($end_y-$start_y), 'start' => { 'x' => $start_x, 'y' => $start_y}, 'dir' => "S"};
        }
        elsif ($start_y == $end_y)
        {
            $check_endpoints->();
            if ($start_x > $end_x)
            {
                ($start_x, $end_x) = ($end_x, $start_x);
            }
            foreach my $x (($start_x+1) .. ($end_x-1))
            {
                if ($board[$start_y]->[$x])
                {
                    die "$plank_str crosses logs!"
                }
            }
            return { 'len' => ($end_x-$start_x), 'start' => { 'x' => $start_x, 'y' => $start_y}, 'dir' => "E" };
        }
        elsif (($end_x-$start_x) == ($end_y - $start_y))
        {
            $check_endpoints->();
            if ($start_x > $end_x)
            {
                ($start_x, $end_x) = ($end_x, $start_x);
                ($start_y, $end_y) = ($end_y, $start_y);
            }
            foreach my $i (1 .. ($end_x-$start_x-1))
            {
                if ($board[$start_y+$i]->[$start_x+$i])
                {
                    die "$plank_str crosses logs!"
                }
            }
            if (! grep { $_ eq "SE" } @{$self->{'dirs'}})
            {
                die "$plank_str is not aligned horizontally or vertically.";
            }
            return 
                { 
                    'len' => ($end_x - $start_x), 
                    'start' => 
                        { 
                            'x' => $start_x,
                            'y' => $start_y,
                        },
                    'dir' => "SE",
                };
        }
        else
        {
            die "$plank_str is not aligned horizontally or vertically.";
        }
    };
    
    foreach my $p (@$planks_in)
    {
        push @planks, $get_plank->($p);
    }

    $self->{'width'} = $width;
    $self->{'height'} = $height;
    $self->{'goal_x'} = $goal_x;
    $self->{'goal_y'} = $goal_y;
    $self->{'board'} = \@board;
    $self->{'plank_lens'} = [ map { $_->{'len'} } @planks ];
    
    my $state = [ 0,  (map { ($_->{'start'}->{'x'}, $_->{'start'}->{'y'}, (($_->{'dir'} eq "E") ? 0 : ($_->{'dir'} eq "SE") ? 2 : 1)) } @planks) ];
    $self->process_plank_data($state);

    #{
    #    use Data::Dumper;
    #
    #    my $d = Data::Dumper->new([$self, $state], ["\$self", "\$state"]);
    #    print $d->Dump();
    #}

    return $state;
}

sub process_plank_data
{
    my $self = shift;

    my $state = shift;

    my $active = $state->[0];

    my @planks = 
        (map 
            { 
                { 
                    'len' => $self->{'plank_lens'}->[$_], 
                    'x' => $state->[$_*3+1], 
                    'y' => $state->[$_*3+1+1], 
                    'dir' => $state->[$_*3+2+1],
                    'active' => 0,
                } 
            } 
            (0 .. (scalar(@{$self->{'plank_lens'}}) - 1))
        );

   
    foreach my $p (@planks)
    {
        my $p_dir = $p->{'dir'};
        my $dir = ($p_dir == 0) ? "E" : ($p_dir == 1) ? "S" : "SE";
        $p->{'dir'} = $dir;
    
        $p->{'end_x'} = $p->{'x'} + $cell_dirs{$dir}->[0] * $p->{'len'};
        $p->{'end_y'} = $p->{'y'} + $cell_dirs{$dir}->[1] * $p->{'len'};
    }

    # $ap is short for active plank
    my $ap = $planks[$active];
    $ap->{'active'} = 1;

    my (@queue);
    push @queue, [$ap->{'x'}, $ap->{'y'}], [$ap->{'end_x'}, $ap->{'end_y'}];
    undef($ap);
    while (my $point = pop(@queue))
    {
        my ($x,$y) = @$point;
        foreach my $p (@planks)
        {
            if ($p->{'active'})
            {
                next;
            }
            if (($p->{'x'} == $x) && ($p->{'y'} == $y))
            {
                $p->{'active'} = 1;
                push @queue, [$p->{'end_x'},$p->{'end_y'}];
            }
            if (($p->{'end_x'} == $x) && ($p->{'end_y'} == $y))
            {
                $p->{'active'} = 1;
                push @queue, [$p->{'x'},$p->{'y'}];
            }
        }
    }
    foreach my $i (0 .. $#planks)
    {
        if ($planks[$i]->{'active'})
        {
            $state->[0] = $i;
            return \@planks;
        }
    }
}

sub pack_state
{
    my $self = shift;

    my $state_vector = shift;
    return pack("c*", @$state_vector);
}

sub unpack_state
{
    my $self = shift;
    my $state = shift;
    return [ unpack("c*", $state) ];
}

sub display_state
{
    my $self = shift;
    my $state = shift;

    my $plank_data = $self->process_plank_data($state);

    my @strings;
    foreach my $p (@$plank_data)
    {
        push @strings, sprintf("(%i,%i) -> (%i,%i) %s", $p->{'x'}, $p->{'y'}, $p->{'end_x'}, $p->{'end_y'}, ($p->{'active'} ? "[active]" : ""));
    }
    return join(" ; ", @strings);
}

sub check_if_final_state
{
    my $self = shift;

    my $state = shift;

    my $plank_data = $self->process_plank_data($state);

    my $goal_x = $self->{'goal_x'};
    my $goal_y = $self->{'goal_y'};

    return (scalar(grep { (($_->{'x'} == $goal_x) && ($_->{'y'} == $goal_y)) || 
                  (($_->{'end_x'} == $goal_x) && ($_->{'end_y'} == $goal_y)) 
                }
                @$plank_data) > 0);
}

sub enumerate_moves
{
    my $self = shift;

    my $state = shift;

    my $plank_data = $self->process_plank_data($state);

    # Declare some accessors
    my $board = $self->{'board'};
    my $width = $self->{'width'};
    my $height = $self->{'height'};

    my $dirs_ptr = $self->{'dirs'};

    my @moves;

    for my $to_move_idx (0 .. $#$plank_data)
    {
        my $to_move = $plank_data->[$to_move_idx];
        my $len = $to_move->{'len'};
        if (!($to_move->{'active'}))
        {
            next;
        }
        foreach my $move_to (@$plank_data)
        {
            if (!($move_to->{'active'}))
            {
                next;
            }
            for my $point ([$move_to->{'x'}, $move_to->{'y'}], [$move_to->{'end_x'}, $move_to->{'end_y'}])
            {
                my ($x, $y) = @$point;
                DIR_LOOP: for my $dir (@$dirs_ptr) # (qw(E W S N))
                {
                    # Find the other ending points of the plank
                    my $other_x = $x + $cell_dirs{$dir}->[0] * $len;
                    my $other_y = $y + $cell_dirs{$dir}->[1] * $len;
                    # Check if we are within bounds
                    if (($other_x < 0) || ($other_x >= $width))
                    {
                        next;
                    }
                    if (($other_y < 0) || ($other_y >= $height))
                    {
                        next;
                    }

                    # Check if there is a stump at the other end-point
                    if (! $board->[$other_y]->[$other_x])
                    {
                        next;
                    }

                    # Check the validity of the intermediate points.
                    for(my $offset = 1 ; $offset < $len ; $offset++)
                    {
                        my $ix = $x + $cell_dirs{$dir}->[0] * $offset;
                        my $iy = $y + $cell_dirs{$dir}->[1] * $offset;
                        
                        if ($board->[$iy]->[$ix])
                        {
                            next DIR_LOOP;
                        }
                        # Check if another plank has this point in between
                        my $collision_plank_idx = 0;
                        for my $plank (@$plank_data)
                        {
                            # Make sure we don't test a plank against
                            # a collisions with itself.
                            if ($collision_plank_idx == $to_move_idx)
                            {
                                next;
                            }
                            my $p_x = $plank->{'x'};
                            my $p_y = $plank->{'y'};
                            my $plank_dir = $plank->{'dir'};
                            for my $i (0 .. $plank->{'len'})
                            {
                                if (($p_x == $ix) && ($p_y == $iy))
                                {
                                    next DIR_LOOP;
                                }
                            }
                            continue
                            {
                                $p_x += $cell_dirs{$plank_dir}->[0];
                                $p_y += $cell_dirs{$plank_dir}->[1];
                            }
                        }
                        continue
                        {
                            $collision_plank_idx++;
                        }
                    }

                    # A perfectly valid move - let's add it.
                    push @moves, { 'p' => $to_move_idx, 'x' => $x, 'y' => $y, 'dir' => $dir };
                }
            }
        }
    }

    return @moves;
}

sub perform_move
{
    my $self = shift;

    my $state = shift;
    my $m = shift;

    my $plank_data = $self->process_plank_data($state);

    my ($x,$y,$p,$dir) = @{$m}{qw(x y p dir)};
    my $dir_idx;
    if ($dir eq "S")
    {
        $dir_idx = 1;
    }
    elsif ($dir eq "E")
    {
        $dir_idx = 0;
    }
    elsif ($dir eq "N")
    {
        $dir_idx = 1;
        $y -= $self->{'plank_lens'}->[$p];
    }
    elsif ($dir eq "W")
    {
        $dir_idx = 0;
        $x -= $self->{'plank_lens'}->[$p];
    }
    elsif ($dir eq "NW")
    {
        $dir_idx = 2;
        $y -= $self->{'plank_lens'}->[$p];
        $x -= $self->{'plank_lens'}->[$p];        
    }
    elsif ($dir eq "SE")
    {
        $dir_idx = 2;
    }

    my $new_state = [ @$state ];

    @$new_state[0] = $p;
    @$new_state[(1+$p*3) .. (1+$p*3+2)] = ($x,$y,$dir_idx);

    $self->process_plank_data($new_state);
    
    return $new_state;
}

sub render_move
{
    my $self = shift;

    my $move = shift;

    if ($move)
    {
        return sprintf("Move the Plank of Length %i to (%i,%i) %s", $self->{'plank_lens'}->[$move->{'p'}], @{$move}{qw(x y dir)});
    }
    else
    {
        return "";
    }
}
