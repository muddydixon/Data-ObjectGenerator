package Data::ObjectGenerator::Template;

use 5.006;
use strict;
use warnings;
use Carp;

use String::Random;

our $VERSION = '0.0.1';

sub Number {
    my $self = shift;
    my ($min, $max, $round, $isDouble) = @_;
    my $range = $max - $min;

    return sub {
        my $val = rand() * $range + $min;
        if($isDouble){
            return $val;
        }else{
            if(defined $round){
                return int($val / $round) * $round;
            }else{
                return int($val);
            }
        }
    }
}

sub String {
    my $self = shift;
    my $proto = shift;
    my $gen = new String::Random();
    
    eval{
        $gen->randpattern($proto)
    };
    if($@){
        croak "cannot parse $proto pattern";
    }
    
    return sub {
        return $gen->randpattern($proto);
    }
}

sub Enum {
    my $self = shift;
    my @patterns = @_;
    my $len = scalar @patterns;

    return sub {
        return $patterns[int(rand() * $len)];
    }
}

1; # End of Data::ObjectGenerator::Template
