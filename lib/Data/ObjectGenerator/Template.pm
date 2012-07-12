package Data::ObjectGenerator::Template;

use 5.006;
use strict;
use warnings;
use Carp;

use String::Random;

our $VERSION = '0.0.1';

sub _extendFormula {
    my $val = shift;
    if(defined $val and $val =~ /^\%\s(.+)\s\%$/){
        my $code = $1;
        eval($code);
        if($@){
            croak "cannot eval $code";
        }
        return eval($code);
    }else{
        return $val;
    }
}

sub Number {
    my $self = shift;
    my ($min, $max, $round, $isDouble) = @_;
    $min = &_extendFormula($min);
    $max = &_extendFormula($max);
    $round = &_extendFormula($round);
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
    if($len == 1){
        my $pat = &_extendFormula($patterns[0]);
        if(ref($pat) ne 'ARRAY'){
            croak "required ArrayRef in ".$patterns[0];
        }
        @patterns = @$pat;
        $len = scalar @patterns;
    }
    return sub {
        return $patterns[int(rand() * $len)];
    }
}

1; # End of Data::ObjectGenerator::Template
