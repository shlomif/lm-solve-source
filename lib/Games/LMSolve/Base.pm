package Games::LMSolve::Base;

use strict;

use Getopt::Long;

use vars qw($VERSION);

$VERSION = '0.7.8';

use Exporter;

use vars qw(@ISA @EXPORT_OK);

@ISA=qw(Exporter);

@EXPORT_OK=qw(%cell_dirs);

no warnings qw(recursion);

use vars qw(%cell_dirs);

%cell_dirs = 
    (
        'N' => [0,-1],
        'NW' => [-1,-1],
        'NE' => [1,-1],
        'S' => [0,1],
        'SE' => [1,1],
        'SW' => [-1,1],
        'E' => [1,0],
        'W' => [-1,0],
    );

sub new
{
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->initialize(@_);

    return $self;    
}

sub initialize
{
    my $self = shift;

    $self->{'state_collection'} = { };
    $self->{'cmd_line'} = { };

    $self->{'num_iters'} = 0;

    return 0;
}

sub die_on_abstract_function
{
    my ($package, $filename, $line, $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    die ("The abstract function $subroutine() was " . 
        "called, while it needs to be overrided by the derived class.\n");
}

sub input_board
{
    return &die_on_abstract_function();
}

# A function that accepts the expanded state (as an array ref)
# and returns an atom that represents it.
sub pack_state
{
    return &die_on_abstract_function();
}

# A function that accepts an atom that represents a state 
# and returns an array ref that represents it.
sub unpack_state
{
    return &die_on_abstract_function();
}

# Accept an atom that represents a state and output a 
# user-readable string that describes it.
sub display_state
{
    return &die_on_abstract_function();
}

# This function checks if a state it receives as an argument is a
# dead-end one.
sub check_if_unsolvable
{
    return &die_on_abstract_function();
}

sub check_if_final_state
{
    return &die_on_abstract_function();
}

# This function enumerates the moves accessible to the state.
# If it returns a move, it still does not mean that this move is a valid 
# one. I.e: it is possible that it is illegal to perform it.
sub enumerate_moves
{
    return &die_on_abstract_function();
}

# This is a function that should be overrided in case
# rendering the move into a string is non-trivial.
sub render_move
{
    my $self = shift;

    my $move = shift;

    return $move;
}

# This function accepts a state and a move. It tries to perform the
# move on the state. If it is succesful, it returns the new state.
#
# Else, it returns undef to indicate that the move is not possible.
sub perform_move
{
    return &die_on_abstract_function();
}

sub set_run_time_states_display
{
    my $self = shift;
    my $states_display = shift;

    if (! $states_display)
    {
        $self->{'cmd_line'}->{'rt_states_display'} = undef;
    }
    else
    {
        $self->{'cmd_line'}->{'rt_states_display'} = 1;
        $self->{'run_time_display_callback'} = $states_display;
    }

    return 0;
}

sub solve_brfs_or_dfs
{
    my $self = shift;
    my $state_collection = $self->{'state_collection'};
    my $initial_state = shift;
    my $is_dfs = shift;
    my %args = @_;
    
    my $run_time_display = $self->{'cmd_line'}->{'rt_states_display'};
    my $rtd_callback = $self->{'run_time_display_callback'};
    my $max_iters = $args{'max_iters'} || (-1);
    my $not_check_iters = ($max_iters < 0);
    
    my (@queue, $state, $coords, $depth, @moves, $new_state);

    push @queue, $initial_state;

    my $num_iters = $self->{'num_iters'};
    my @ret;

    while (scalar(@queue) && 
           (
               $not_check_iters || 
               ($max_iters > $num_iters)
           )
          )
    {
        if ($is_dfs)
        {
            $state = pop(@queue);
        }
        else
        {
            $state = shift(@queue);
        }
        $coords = $self->unpack_state($state);
        $depth = $state_collection->{$state}->{'d'};

        $num_iters++;

        # Output the current state to the screen, assuming this option
        # is set.
        if ($run_time_display)
        {
            $rtd_callback->(
                $self,
                'depth' => $depth,
                'state' => $coords,
                'move' => $state_collection->{$state}->{'m'},
                'num_iters' => $num_iters,
            );
            # print ((" " x $depth) . join(",", @$coords) . " M=" . $self->render_move($state_collection->{$state}->{'m'}) ."\n");
        }
        
        if ($self->check_if_unsolvable($coords))
        {
            next;
        }

        if ($self->check_if_final_state($coords))
        {
            @ret = ("solved", $state);
            goto Return;
        }
        
        @moves = $self->enumerate_moves($coords);

        foreach my $m (@moves)
        {
            my $new_coords = $self->perform_move($coords, $m);
            # Check if this move leads nowhere and if so - skip to the next move.
            if (!defined($new_coords))
            {
                next;
            }
            
            $new_state = $self->pack_state($new_coords);
            if (! exists($state_collection->{$new_state}))
            {
                $state_collection->{$new_state} = 
                    {
                        'p' => $state, 
                        'm' => $m, 
                        'd' => ($depth+1)
                    };
                push @queue, $new_state;
            }
        }
    }

    @ret = ("unsolved", undef);
    
    Return:

    $self->{'num_iters'} = $num_iters;

    return @ret;
}

sub run_length_encoding
{
    my @moves = @_;
    my @ret = ();

    my $prev_m = shift(@moves);
    my $count = 1;
    my $m;
    while ($m = shift(@moves))
    {
        if ($m eq $prev_m)
        {
            $count++;            
        }
        else
        {
            push @ret, [ $prev_m, $count];
            $prev_m = $m;
            $count = 1;
        }
    }
    push @ret, [$prev_m, $count];

    return @ret;    
}

my %scan_functions =
(
    'dfs' => sub {
        my $self = shift;
        my $initial_state = shift;

        return $self->solve_brfs_or_dfs($initial_state, 1, @_);
    },
    'brfs' => sub {
        my $self = shift;
        my $initial_state = shift;

        return $self->solve_brfs_or_dfs($initial_state, 0, @_);
    },
);


sub solve_state
{
    my $self = shift;
    
    my $initial_coords = shift;
    
    my $state = $self->pack_state($initial_coords);
    $self->{'state_collection'}->{$state} = {'p' => undef, 'd' => 0};

    return 
        $scan_functions{$self->{'cmd_line'}->{'scan'}}->(
            $self,
            $state,
            @_
        );
}

sub solve_file
{
    my $self = shift;
    
    my $filename = shift;

    my $initial_coords = $self->input_board($filename);

    return $self->solve_state($initial_coords);
}

sub display_solution
{
    my $self = shift;

    my @ret = @_;

    my $state_collection = $self->{'state_collection'};

    my $output_states = $self->{'cmd_line'}->{'output_states'};
    my $to_rle = $self->{'cmd_line'}->{'to_rle'};

    my $echo_state = 
        sub {
            my $state = shift;
            return $output_states ? 
                ($self->display_state($state) . ": Move = ") :
                "";
        };    

    print $ret[0], "\n";

    if ($ret[0] eq "solved")
    {
        my $key = $ret[1];
        my $s = $state_collection->{$key};
        my @moves = ();
        my @states = ($key);

        while ($s->{'p'})
        {
            push @moves, $s->{'m'};
            $key = $s->{'p'};
            $s = $state_collection->{$key};
            push @states, $key;
        }
        @moves = reverse(@moves);
        @states = reverse(@states);
        if ($to_rle)
        {
            my @moves_rle = &run_length_encoding(@moves);
            my ($m, $sum);

            $sum = 0;
            foreach $m (@moves_rle)
            {            
                print $echo_state->($states[$sum]) . $self->render_move($m->[0]) . " * " . $m->[1] . "\n";
                $sum += $m->[1];
            }
        }
        else
        {
            my ($a);
            for($a=0;$a<scalar(@moves);$a++)
            {
                print $echo_state->($states[$a]) . $self->render_move($moves[$a]) . "\n";
            }            
        }
        if ($output_states)
        {
            print $self->display_state($states[$a]), "\n";
        }
    }
}

sub _default_rtd_callback
{
    my $self = shift;

    my %args = @_;
    print ((" " x $args{depth}) . join(",", @{$args{state}}) . " M=" . $self->render_move($args{move}) ."\n");
}

sub main
{
    my $self = shift;

    # This is a flag that specifies whether to present the moves in Run-Length
    # Encoding.
    my $to_rle = 1;
    my $output_states = 0;
    my $scan = "brfs";
    my $run_time_states_display = 0;

    #my $p = Getopt::Long::Parser->new();
    if (! GetOptions('rle!' => \$to_rle, 
        'output-states!' => \$output_states,
        'method=s' => \$scan,
        'rtd!' => \$run_time_states_display,
        ))
    {
        die "Incorrect options passed!\n"
    }

    if (!exists($scan_functions{$scan}))
    {
        die "Unknown scan \"$scan\"!\n";
    }

    $self->{'cmd_line'}->{'to_rle'} = $to_rle;
    $self->{'cmd_line'}->{'output_states'} = $output_states;
    $self->{'cmd_line'}->{'scan'} = $scan;
    $self->set_run_time_states_display($run_time_states_display && \&_default_rtd_callback);

    my $filename = shift(@ARGV) || "board.txt";

    my @ret = $self->solve_file($filename);

    $self->display_solution(@ret);
}

1;

