#!/usr/bin/env perl
############################################################
#
#
use strict;
use warnings;
use lib './lib/';

use Config::JSON;
use Data::Dumper;
use Getopt::Std;
use Data::ObjectGenerator;
use Data::ObjectGenerator::Template;
use JSON;
use POSIX 'strftime';

our $VERSION = '0.0.1';

my $defaultNum = 10;

my %opt;
getopts('p:t:n:o:f:', \%opt);
my $template = $opt{t};
my $num = $opt{n} || $defaultNum;
my $plan = $opt{p};
my $format = $opt{f} || 'json';
my $output = $opt{o} || 'stdout';

(&usage() or exit -1) unless defined $template or defined $plan;

############################################################
#
if(defined $plan){
    my $config = Config::JSON->new($plan);
    $config = $config->config;
    foreach my $key (keys %$config){
        if($config->{$key}){
            next unless ref($config->{$key}) eq 'HASH';
            if(defined $config->{$key}{file}){
                my $data = &generate($config->{$key}{file}, $config->{$key}{num});
                &write($data, $config->{$key}{output}, $config->{$key}{format}, $key)
            }elsif(defined $config->{$key}{template}){
                # TODO
            }
        }
    }
}elsif(defined $template){
    my $data = &generate($template, $num);
    &write($data, $output, $format, "test");
}


sub write {
    my ($data, $output, $format, $key) = @_;
    my $OUT = undef;
    if(!defined $output or $output eq 'stdout'){
        $OUT = *STDOUT;
    }else{
        open $OUT, ">$output" or die "cannot open file $output";
    }
    $format = $format || 'json';

    my $f = &Formatter($format);

    my $sep = undef;
    if($format =~ /^(.)sv$/){
        if($1 eq 'c'){
            $sep = ",";
        }elsif($1 eq 't'){
            $sep = "\t";
        }
        # print header
        print $OUT join($sep, sort keys %{$data->[0]})."\n"
    }
    
    foreach my $d (@$data){
        print $OUT $f->($d, {sep => $sep, key => $key})."\n";
    }
}

sub Formatter {
    my $type = shift;
    $type =~ tr/[A-Z]/[a-z/;

    if($type eq 'json'){
        my $json = JSON->new();
        return sub {
            my $obj = shift;
            my $opt = shift;
            return $json->encode($obj);
        }
    }elsif($type eq 'fluentd'){
        my $json = JSON->new();
        return sub {
            my $obj = shift;
            my $opt = shift;
            my @lt = localtime(time);

            return strftime("%Y/%m/%d %H:%M:%S %z", localtime)." $opt->{key}: ".$json->encode($obj);
        }
    }elsif($type =~ /^.sv/){
        return sub {
            my $obj = shift;
            my $opt = shift;
            return join $opt->{sep}, map{ $obj->{$_} } sort keys %$obj;
        }
    }
}

sub generate {
    my ($template, $num) = @_;
    $num = $num || $defaultNum;

    my $gen = Data::ObjectGenerator->new(file => $template);
    my $dat = $gen->gen($num);

    return $dat;
}



############################################################
sub usage {
    print <<EOF
datagen.pl version $VERSION

usage: ./datagen.pl [-p planfile] [-t templatefile] [-n num]

  p : data generator plan json file
  t : template json file
  n : number of data
  f : format of output data: json, csv
  o : output stdout or filename. default= stdout
EOF
}
