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

=head1 NAME

Games::LMSolve::Base - base class for puzzle solvers.

=head1 SYNOPSIS

    package MyPuzzle::Solver;
    
    @ISA = qw(Games::LMSolve::Base);

    # Override these methods:

    sub input_board { ... }
    sub pack_state { ... }
    sub unpack_state { ... }
    sub display_state { ... }
    sub check_if_final_state { ... }
    sub enumerate_moves { ... }
    sub perform_move { ... }

    # Optionally: 
    sub render_move { ... }
    sub check_if_unsolvable { ... }

    package main;

    my $self = MyPuzzle::Solver->new();

    $self->solve_board($filename);

=head1 DESCRIPTION
    
This class implements a generic solver for single player games. In order
to use it, one must inherit from it and implement some abstract methods.
Afterwards, its interface functions can be invoked to actually solve
the game.

=head1 Methods to Override

=cut
    

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
    $self->{'cmd_line'} = { 'scan' => "brfs", };

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

=head2 input_board($self, $file_spec);

This method is responsible to read the "board" (the permanent parameters) of 
the puzzle and its initial state. It should place the board in the object's
keys, and return the initial state. (in unpacked format).

Note that $file_spec can be either a filename (if it's a string) or a reference
to a filehandle, or a reference to the text of the board. input_board() should
handle all cases.

You can look at the Games::LMSolve::Input module for methods that facilitate
inputting a board.
=cut

sub input_board
{
    return &die_on_abstract_function();
}

=head2 pack_state($self, $state_vector)

This function accepts a state in unpacked form and should return it in packed
format. A state in unpacked form can be any perl scalar (as complex as you 
like). A state in packed form must be a string.

=cut

# A function that accepts the expanded state (as an array ref)
# and returns an atom that represents it.
sub pack_state
{
    return &die_on_abstract_function();
}

=head2 unpack_state($self, $packed_state)

This function accepts a state in a packed form and should return it in its
expanded form.

=cut

# A function that accepts an atom that represents a state 
# and returns an array ref that represents it.
sub unpack_state
{
    return &die_on_abstract_function();
}

=head2 display_state($self, $packed_state)

Accepts a packed state and should return the user-readable string 
representation of the state.

=cut

# Accept an atom that represents a state and output a 
# user-readable string that describes it.
sub display_state
{
    return &die_on_abstract_function();
}

=head2 check_if_final_state($self, $state_vector)

This function should return 1 if the expanded state $state_vector is 
a final state, and the game is over.

=cut

sub check_if_final_state
{
    return &die_on_abstract_function();
}

=head2 enumerate_moves($self, $state_vector)

This function accepts an expanded state and should return an array of moves
that can be performed on this state.

=cut

# This function enumerates the moves accessible to the state.
# If it returns a move, it still does not mean that this move is a valid 
# one. I.e: it is possible that it is illegal to perform it.
sub enumerate_moves
{
    return &die_on_abstract_function();
}

=head2 perform_move($self, $state_vector, $move)

This method accepts an expanded state and a move. It should try to peform
the move on the state. If it is successful, it should return the new
state. Else, it should return undef, to indicate that the move cannot
be performed.

=cut

# This function accepts a state and a move. It tries to perform the
# move on the state. If it is succesful, it returns the new state.
#
# Else, it returns undef to indicate that the move is not possible.
sub perform_move
{
    return &die_on_abstract_function();
}

=head2 check_if_unsolvable($self, $state_vector) (optional over-riding)

This method returns the verdict if C<$state_vector> cannot be solved. This
method defaults to returning 0, and it is usually safe to keep it that way.

=cut

# This function checks if a state it receives as an argument is a
# dead-end one.
sub check_if_unsolvable
{
    return 0;
}

=head2 render_move($self, $move) (optional overriding)

This function returns the user-readable stringified represtantion of a
move.

=cut

# This is a function that should be overrided in case
# rendering the move into a string is non-trivial.
sub render_move
{
    my $self = shift;

    my $move = shift;

    return $move;
}

=head1 API

=cut

sub solve_brfs_or_dfs
{
    my $self = shift;
    my $state_collection = $self->{'state_collection'};
    my $is_dfs = shift;
    my %args = @_;
    
    my $run_time_display = $self->{'cmd_line'}->{'rt_states_display'};
    my $rtd_callback = $self->{'run_time_display_callback'};
    my $max_iters = $args{'max_iters'} || (-1);
    my $check_iters = ($max_iters >= 0);
    
    my (@queue, $state, $coords, $depth, @moves, $new_state);

    if (exists($args{'initial_state'}))
    {
        push @queue, $initial_state;
    }

    my @ret;

    @ret = ("unsolved", undef);

    while (scalar(@queue))
    {
        if ($check_iters && ($max_iters <= $self->{'num_iters'}))
        {
            @ret = ("interrupted", undef);
            goto Return;
        }
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

        $self->{'num_iters'}++;

        # Output the current state to the screen, assuming this option
        # is set.
        if ($run_time_display)
        {
            $rtd_callback->(
                $self,
                'depth' => $depth,
                'state' => $coords,
                'move' => $state_collection->{$state}->{'m'},
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
    
    Return:

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
        $self->run_scan(
            'initial_state' => $state,
            @_
        );
}

=head2 $self->solve_board($file_spec, %args)

Solves the board specification specified in $file_spec. %args specifies 
optional arguments. Currently there is one: 'max_iters' that specifies the 
maximal iterations to run.

Returns whatever run_scan returns.

=cut
sub solve_board
{
    my $self = shift;
    
    my $filename = shift;

    my $initial_coords = $self->input_board($filename);

    return $self->solve_state($initial_coords, @_);
}

=head2 $self->run_scan(%args)

Continues the current scan. %args may contain the 'max_iters' parameter
to specify a maximal iterations limit.

Returns two values. The first is a progress indicator. "solved" means the 
puzzle was solved. "unsolved" means that all the states were covered and
the puzzle was proven to be unsolvable. "interrupted" means that the
scan was interrupted in the middle, and could be proved to be either 
solvable or unsolvable.

The second argument is the final state and is valid only if the progress
value is "solved".

=cut

sub run_scan
{
    my $self = shift;

    my %args = @_;

    return 
        $scan_functions{$self->{'cmd_line'}->{'scan'}}->(
            $self,
            %args
        );
}

=head2 $self->get_num_iters()

Retrieves the current number of iterations.

=cut

sub get_num_iters
{
    my $self = shift;

    return $self->{'num_iters'};
}

=head2 $self->display_solution($progress_code, $final_state)

If you input this message with the return value of run_scan() you'll get
a nice output of the moves to stdout.

=cut

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

    my @ret = $self->solve_board($filename);

    $self->display_solution(@ret);
}

=head2 $self->set_run_time_states_display(\&states_display_callback)

Sets the run time states display callback to \&states_display_callback.

This display callback accepts a reference to the solver and also the following
arguments in key => value pairs:

"state" - the expanded state.
"depth" - the depth of the state.
"move" - the move leading to this state from its parent.

=cut

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

=head1 SEE ALSO

L<Games::LMSolve::Input>

=head1 AUTHORS

Shlomi Fish, E<lt>shlomif@vipe.technion.ac.ilE<gt>

=cut 

1;

