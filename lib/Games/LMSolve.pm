package Games::LMSolve;

use strict;

use Getopt::Long;
use Pod::Usage;

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

    %args = @_;
    
    $self->{'games_solvers'} = {};

    $self->register_all_solvers();

    if (exists($args{'default_variant'}))
    {
        $self->set_default_variant($args{'default_variant'});
    }
    
    return 0;
}

sub set_default_variant
{
    my $self = shift;

    my $variant = shift;

    $self->{'default_variant'} = $variant;

    return 0;
}

sub register_solvers
{
    my $self = shift;

    my $games = shift;

    $self->{'games_solvers'} = { %{$self->{'games_solvers'}}, %$games};

    return 0;
}

sub register_all_solvers
{
    my $self = shift;

    return 0;
}

sub main
{
    my $self = shift;

    my $variant = $self->{'default_variant'};
    my $help = 0;
    my $man = 0;

    Getopt::Long::Configure('pass_through');
    GetOptions(
        "g|game=s" => \$variant, 
        'help|h|?' => \$help, 
        'man' => \$man
        ) or pod2usage(2);

    pod2usage(1) if $help;
    pod2usage(-exitstatus => 0, -verbose => 2) if $man;

    if (!exists($self->{'games_solvers'}->{$variant}))
    {
        die "Unknown game variant \"$variant\"";
    }

    my $class = $self->{'games_solvers'}->{$variant};
    my $game;
    if (ref($class) eq "CODE")
    {
        $game = $class->();
    }
    else
    {
        $game = $class->new();
    }
    $game->main();
}
1;


