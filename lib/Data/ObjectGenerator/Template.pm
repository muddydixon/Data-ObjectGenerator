package Data::ObjectGenerator::Template;

use 5.006;
use strict;
use warnings;
use Carp;

use String::Random;
use Data::Dumper;

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
    my %opts = @_;
    
    $opts{min} = &_extendFormula($opts{min});
    $opts{max} = &_extendFormula($opts{max});
    $opts{round} = &_extendFormula($opts{round});

    my $range = $opts{max} - $opts{min};

    return sub {
        my $val = rand() * $range + $opts{min};
        if($opts{isDouble}){
            return $val;
        }else{
            if(defined $opts{round}){
                return int($val / $opts{round}) * $opts{round};
            }else{
                return int($val);
            }
        }
    }
}

sub String {
    my $self = shift;
    my %opts = @_;
    my $gen = new String::Random();

    eval{
        $gen->randpattern($opts{pat})
    };
    if($@){
        croak "cannot parse $opts{proto} pattern";
    }
    
    return sub {
        return $gen->randpattern($opts{pat});
    }
}

sub Enum {
    my $self = shift;
    my %opts = @_;
    
    my @items = @{$opts{items}};
    my $len = scalar @items;
    if($len == 1){
        my $pat = &_extendFormula($items[0]);
        if(ref($pat) ne 'ARRAY'){
            croak "required ArrayRef in ".$items[0];
        }
        @items = @$pat;
        $len = scalar @items;
    }
    return sub {
        return $items[int(rand() * $len)];
    }
}

1; # End of Data::ObjectGenerator::Template
