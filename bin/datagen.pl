#!/usr/bin/env perl
############################################################
#
#
use strict;
use warnings;
use lib './lib/';

use Config::JSON;
use Getopt::Std;
use Data::Dumper;

use Data::ObjectGenerator;
use Data::ObjectGenerator::Template;

use POSIX 'strftime';
use JSON;
use MongoDB;
use DBI;
use Fluent::Logger;

our $VERSION = '0.0.2';

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
                # data generate templated by file
                my $data = &generate($config->{$key}{file}, $config->{$key}{num});

                # write data
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
    
    $output = $output || 'stdout';

    my $f = sub{
        return shift;
    };
    if(defined $format){
        $f = &Formatter($format);
    }
    my $writer = &Writer($output);

    my $sep = undef;
    if(defined $format and $format =~ /^(.)sv$/){
        if($1 eq 'c'){
            $sep = ",";
        }elsif($1 eq 't'){
            $sep = "\t";
        }
        # print header
        $writer->(join($sep, sort keys %{$data->[0]})."\n");
    }
    
    foreach my $d (@$data){
        $writer->($f->($d, {sep => $sep, key => $key}));
    }
}

sub Writer {
    my $output = shift;
    
    my $OUT = *STDOUT;
    if(defined $output){
        if(ref($output) eq 'HASH'){
            if($output->{type} eq 'file' and defined $output->{path} ){
                open $OUT, ">$output->{path}" or die "cannot open file $output";
            }elsif($output->{type} eq 'mongo'){
                my $host = $output->{host} || "localhost";
                my $port = $output->{port} || 27017;
                my $db = $output->{db} || "test";
                my $collection = $output->{collection} || "sample";
                my $user = $output->{user};
                my $pass = $output->{pass};

                my $con = MongoDB::Connection->new(host => $host, port => $port);
                my $database = $con->get_database($db);
                my $col = $database->get_collection($collection);
                my $json = JSON->new;
                
                return sub {
                    my $obj = shift;
                    eval {
                        $col->insert($obj);
                    };
                    if ($@){
                        warn "cannot insert data to mongo $@";
                    }
                };
            }elsif($output->{type} eq 'mysql'){
                my $host = $output->{host} || "localhost";
                my $port = $output->{port} || 3306;
                my $db = $output->{db} || "test";
                my $table = $output->{table} || "sample";
                my $user = $output->{user} || "";
                my $pass = $output->{pass} || "";

                my $dsn = "DBI:mysql:database=$db;host=$host;port=$port;";
                my $dbh = undef;
                eval {
                    $dbh = DBI->connect($dsn, $user, $pass);
                };
                if ($@){
                    warn "cannot connect db $dsn";
                    my $json = JSON->new;
                    return sub {
                        my $obj = shift;
                        my $str = $json->encode($obj);
                        print $OUT $str;
                    };
                }
                
                return sub {
                    my $obj = shift;
                    my @keys = sort keys %$obj;
                    my $sth = $dbh->prepare("INSERT INTO $table (".(join ",", @keys).") VALUES ("."?, "x(scalar @keys - 1)."?)");
                    
                    eval{
                        $sth->execute(map{$obj->{$_}} @keys);
                    };
                    if($@){
                        warn "cannot insert data to mysql $@";
                    }
                };
            }elsif($output->{type} eq 'fluentd'){
                my $host = $output->{host} || "localhost";
                my $port = $output->{port} || 3306;
                my $tag = $output->{tag} || "test";

                my $logger = Fluent::Logger->new(host => $host, port => $port);

                return sub {
                    my $obj = shift;
                    $logger->post($tag, $obj);
                };
            }
        }elsif($output ne "stdout"){
            open $OUT, ">$output" or die "cannot open file $output";
        }
    }
    return sub {
        my $str = shift;
        print $OUT $str;
    };
}
sub Formatter {
    my $type = shift;
    $type =~ tr/[A-Z]/[a-z/;

    if($type eq 'json'){
        my $json = JSON->new();
        return sub {
            my $obj = shift;
            my $opt = shift;
            return $json->encode($obj)."\n";
        }
    }elsif($type eq 'fluentd'){
        my $json = JSON->new();
        return sub {
            my $obj = shift;
            my $opt = shift;
            my @lt = localtime(time);

            return strftime("%Y/%m/%d %H:%M:%S %z", localtime)." $opt->{key}: ".$json->encode($obj)."\n";
        }
    }elsif($type =~ /^.sv/){
        return sub {
            my $obj = shift;
            my $opt = shift;
            return (join $opt->{sep}, map{ $obj->{$_} } sort keys %$obj) ."\n";
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
