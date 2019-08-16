package Games::LMSolve::Input;

use strict;
use warnings;

package Games::LMSolve::Input::Scalar::FH;

sub TIEHANDLE
{
    my $class  = shift;
    my $self   = {};
    my $buffer = shift;
    $self->{'lines'} =
        [ reverse( my @a = ( $buffer =~ /([^\n]*(?:\n|$))/sg ) ) ];
    bless $self, $class;
    return $self;
}

sub READLINE
{
    my $self = shift;
    return pop( @{ $self->{'lines'} } );
}

sub EOF
{
    my $self = shift;
    return ( scalar( @{ $self->{'lines'} } ) == 0 );
}

package Games::LMSolve::Input;

use English qw/ -no_match_vars /;

=head1 NAME

Games::LMSolve::Input - input class for LM-Solve

=head1 SYNOPSIS

    use Games::LMSolve::Input;

    my $input_obj = Games::LMSolve::Input->new();

    my $file_spec = "board.txt";

    my $spec =
    {
        'dims' => { 'type' => "xy(integer)", 'required' => 1, },
        'planks' => { 'type' => "array(start_end(xy(integer)))",
                      'required' => 1,
                    },
        'layout' => { 'type' => "layout", 'required' => 1,},
    };

    my $input_fields = $input_obj->input_board($filename, $spec);

=head1 DESCRIPTION

This class implements the C<input_board> method, which enables to read boards
in "key = value" format. Several types of values are supported.

=head2 METHODS

=head2 $self->new()

Constrcuts a new object. Accepts no meaningful arguments.

=cut

sub new
{
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->_initialize(@_);

    return $self;
}

sub _initialize
{
    my $self = shift;

    return 0;
}

=head2 $self->input_board($file_spec, $spec);

This method accepts two arguments. C<$file_spec> which is the filename,
reference to a filehandle, or reference to the text containing the board
specification.

$spec is a specification of the board given as a reference to a hash.
The keys are the keys inside the file. The values are references
to hashes containing parameters. The 'required' parameter is given to
specify that an exception should be thrown if this key was not specified. The
other parameter (a mandatory one) is type which specified the type of the
value. Available types are:

=over 8

=item integer

A simple integer (will be returned as a scalar)

=item xy(integer)

An (X,Y) pair. Will be returned as { 'x' => $x, 'y' => $y }.

=item array(xy(integer))

An array of [(X1,Y1),(X2,Y2),(X3,Y3)...] pairs. Will be returned as a
reference to an array of (X,Y) pairs.

=item array(start_end(xy(integer)))

An array of [((SX1,SX2)->(EX1,EX2)), ((SX1,SX2)->(EX1,EX2))...] pairs of
(X,Y) pairs. Will be returned as a reference to an array of

    {
        'start' => { 'x' => $start_x, 'y' => $start_y },
        'end' => { 'x' => $end_x, 'y' => $end_y },
    }

=item layout

This is a generic layout that comes inside a here-document. It is returned
as an array of lines that later have to be processed by another routine.

=back

=cut

sub input_board
{
    my $self = shift;

    my $file_spec = shift;

    my $spec = shift;

    my $ret = {};

    my $file_ref;

    local (*I);

    my $filename_str;

    if ( ref($file_spec) eq "" )
    {
        my $filename = $file_spec;
        open( my $in_fh, "<", $filename )
            || die "Failed to read \"$filename\" : $OS_ERROR";

        $file_ref = $in_fh;
        $filename_str =
            ( $filename eq "-" )
            ? "standard input"
            : "\"$filename\"";
    }
    elsif ( ref($file_spec) eq "GLOB" )
    {
        $file_ref     = $file_spec;
        $filename_str = "FILEHANDLE";
    }
    elsif ( ref($file_spec) eq "SCALAR" )
    {
        tie( *I, "Games::LMSolve::Input::Scalar::FH", $$file_spec );
        $file_ref     = \*I;
        $filename_str = "BUFFER";
    }
    else
    {
        die "Unknown file specification passed to input_board!";
    }

    # Now we have the filehandle *$file_ref opened.

    my $line;
    my $line_num = 0;

    my $read_line = sub {
        if ( eof( *{$file_ref} ) )
        {
            return 0;
        }
        $line = readline( *{$file_ref} );
        ++$line_num;
        chomp($line);
        return 1;
    };

    my $gen_exception = sub {
        my $text = shift;
        close( *{$file_ref} );
        die "$text on $filename_str at line $line_num!\n";
    };

    my $xy_pair = "\\(\\s*(\\d+)\\s*\\,\\s*(\\d+)\\s*\\)";

    while ( $read_line->() )
    {
        # Skip if this is an empty line
        if ( $line =~ /^\s*$/ )
        {
            next;
        }

        # Check if we have a "key =" construct
        if ( $line =~ /^\s*(\w+)\s*=/ )
        {
            my $key = lc($1);

            # Save the line number for safekeeping because a layout or
            # other multi-line value can increase it.
            my $key_line_num = $line_num;

            if ( !exists( $spec->{$key} ) )
            {
                $gen_exception->("Unknown key \"$key\"");
            }
            if ( exists( $ret->{$key} ) )
            {
                $gen_exception->("Key \"$key\" was already inputted!\n");
            }

            # Strip anything up to and including the equal sign
            $line =~ s/^.*?=\s*//;
            my $type = $spec->{$key}->{'type'};
            my $value;
            if ( $type eq "integer" )
            {
                if ( $line =~ /^(\d+)\s*$/ )
                {
                    $value = $1;
                }
                else
                {
                    $gen_exception->(
                        "Key \"$key\" expects an integer as a value");
                }
            }
            elsif ( $type eq "xy(integer)" )
            {
                if ( $line =~ /^\(\s*(\d+)\s*,\s*(\d+)\s*\)\s*$/ )
                {
                    $value = { 'x' => $1, 'y' => $2 };
                }
                else
                {
                    $gen_exception->(
                        "Key \"$key\" expects an (x,y) integral pair as a value"
                    );
                }
            }
            elsif ( $type eq "array(xy(integer))" )
            {

                if ( $line =~ /^\[\s*$xy_pair(\s*\,\s*$xy_pair)*\s*\]\s*$/ )
                {
                    my @elements = ( $line =~ m/$xy_pair/g );
                    my @pairs;
                    while ( scalar(@elements) )
                    {
                        my $x = shift(@elements);
                        my $y = shift(@elements);
                        push @pairs, { 'x' => $x, 'y' => $y };
                    }
                    $value = \@pairs;
                }
                else
                {
                    $gen_exception->(
"Key \"$key\" expects an array of integral (x,y) pairs as a value"
                    );
                }
            }
            elsif ( $type eq "array(start_end(xy(integer)))" )
            {
                my $se_xy_pair = "\\(\\s*$xy_pair\\s*->\\s*$xy_pair\\s*\\)";
                if ( $line =~
                    /^\[\s*$se_xy_pair(\s*\,\s*$se_xy_pair)*\s*\]\s*$/ )
                {
                    my @elements = ( $line =~ m/$se_xy_pair/g );
                    my @pairs;
                    while ( scalar(@elements) )
                    {
                        my ( $sx, $sy, $ex, $ey ) = @elements[ 0 .. 3 ];
                        @elements = @elements[ 4 .. $#elements ];
                        push @pairs,
                            {
                            'start' => { 'x' => $sx, 'y' => $sy },
                            'end'   => { 'x' => $ex, 'y' => $ey }
                            };
                    }
                    $value = \@pairs;
                }
                else
                {
                    $gen_exception->(
"Key \"$key\" expects an array of integral (sx,sy) -> (ex,ey) start/end x,y pairs as a value"
                    );
                }
            }
            elsif ( $type eq "layout" )
            {
                if ( $line =~ /^<<\s*(\w+)\s*$/ )
                {
                    my $terminator = $1;
                    my @lines      = ();
                    my $eof        = 1;
                    while ( $read_line->() )
                    {
                        if ( $line =~ /^\s*$terminator\s*$/ )
                        {
                            $eof = 0;
                            last;
                        }
                        push @lines, $line;
                    }
                    if ($eof)
                    {
                        $gen_exception->(
"End of file reached before the terminator (\"$terminator\") for key \"$key\" was found"
                        );
                    }
                    $value = \@lines;
                }
                else
                {
                    $gen_exception->(
"Key \"$key\" expects a layout specification (<<TERMINATOR_STRING)"
                    );
                }
            }
            else
            {
                $gen_exception->("Unknown type \"$type\"!");
            }

            $ret->{$key} = { 'value' => $value, 'line_num' => $key_line_num };
        }
    }

    close( *{$file_ref} );

    foreach my $key ( keys(%$spec) )
    {
        if ( $spec->{$key}->{'required'} )
        {
            if ( !exists( $ret->{$key} ) )
            {
                die
"The required key \"$key\" was not specified on $filename_str!\n";
            }
        }
    }

    return $ret;
}

=head2 $self->input_horiz_vert_walls_layout($width, $height, \@lines)

Input a horizontal-vertical line layout as exists in a maze.

=cut

sub input_horiz_vert_walls_layout
{
    my $self = shift;

    my $width     = shift;
    my $height    = shift;
    my $lines_ptr = shift;

    my ( @vert_walls, @horiz_walls );

    my $line;
    my $line_num = 0;
    my $y;

    my $get_next_line = sub {
        my $ret = $lines_ptr->{'value'}->[$line_num];
        ++$line_num;

        return $ret;
    };

    my $gen_exception = sub {
        my $msg = shift;
        die(
            $msg . " at line " . ( $line_num + $lines_ptr->{'line_num'} + 1 ) );
    };

    my $input_horiz_wall = sub {
        $line = $get_next_line->();
        if ( length($line) != $width )
        {
            $gen_exception->("Incorrect number of blocks");
        }
        if ( $line =~ /([^ _\-])/ )
        {
            $gen_exception->("Incorrect character \'$1\'");
        }
        push @horiz_walls,
            [ ( map { ( $_ eq "_" ) || ( $_ eq "-" ) } split( //, $line ) ) ];
    };

    my $input_vert_wall = sub {
        $line = $get_next_line->();
        if ( length($line) != $width + 1 )
        {
            $gen_exception->("Incorrect number of blocks");
        }
        if ( $line =~ /([^ |])/ )
        {
            $gen_exception->("Incorrect character \'$1\'");
        }
        push @vert_walls, [ ( map { $_ eq "|" } split( //, $line ) ) ];
    };

    for ( $y = 0 ; $y < $height ; $y++ )
    {
        $input_horiz_wall->();
        $input_vert_wall->();
    }
    $input_horiz_wall->();

    return ( \@horiz_walls, \@vert_walls );
}

=head1 AUTHORS

Written by Shlomi Fish ( L<http://www.shlomifish.org/> )

=cut

1;

