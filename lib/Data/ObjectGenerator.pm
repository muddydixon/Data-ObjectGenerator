package Data::ObjectGenerator;

use 5.006;
use strict;
use warnings;
use Carp;

use Config::JSON;

use Data::ObjectGenerator::Template;

=head1 NAME

Data::ObjectGenerator - The great new Data::ObjectGenerator!

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.2';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Data::ObjectGenerator;

    my $Tmp = Data::ObjectGenerator->Template;

    my $template = {
        "user_id" => $Tmp->Number(50, 100),
        "user_name" => $Tmp->String('Cccnnnnn'),
        "time" => $Tmp->Number(time - 3600 * 24 * 7, time),
        "type" => $Tmp->Enum('hoge', 'fuga', 'piyo'),
        "tag" => "sample",
        "register_hour" => $Tmp->Number(time - 3600 * 24 * 7, time, 3600),
        "average" => $Tmp->Number(100, 500, undef, 1),
    };
    my $generator = new Data::ObjectGenerator->new(template => $template);

    # or

    my $generator = new Data::ObjectGenerator->new(file => "./template.json");

    my $onedata = $generator->one();
    my $data = $generator->gen(1000);
    $data = $generator->pat({"user_id" => [1, 2, 3, 4, 5, 6], "type" => ["hoge", "fuga", "piyo"]});


=head1 SUBROUTINES/METHODS

=head2 CLASS METHODS

=head3 C<< Data::ObjectGenerator->new( %args ) :Data::ObjectGenerator >>

    Creates and return a new data generator with template described by %args:

    my $generator = new Data::ObjectGenerator->new(template => $template);

    # or

    my $generator = new Data::ObjectGenerator->new(file => "./template.json");

=cut

sub new {
    my ($this, %opts) = @_;
    croak "template or file is required" unless $opts{template} or $opts{file};
    my $template = $opts{template} || {};

    if(defined $opts{file}){
        my $config = Config::JSON->new($opts{file});
        $config = $config->{config};
        foreach my $key (keys %$config){
            if(ref($config->{$key}) ne 'HASH'){
                $template->{$key} = $config->{$key};
                next;
            }else{
                my $type = $config->{$key}{type};
                my $def = "";
                if($type eq 'Number'){
                    my ($min, $max, $round, $isDouble) = ($config->{$key}{min} || 0, $config->{$key}{max} || 10000, $config->{$key}{round}, $config->{$key}{isDouble} || 0);
                    $template->{$key} = Data::ObjectGenerator::Template->Number($min, $max, $round, $isDouble);
                }elsif($type eq 'String'){
                    my $pat = $config->{$key}{pat};
                    $template->{$key} = Data::ObjectGenerator::Template->String($pat);
                }elsif($type eq 'Enum'){
                    my $items = $config->{$key}{items};
                    $template->{$key} = Data::ObjectGenerator::Template->Enum(@$items);
                }
            }
        }
    }

    my $self = +{
        template => $template,
        file => $opts{file},
        num => 10,
    };

    return bless $self, $this;
}

=head2 INSTANCE METHODS

=head3 C<< $generator->one() :HashRef >>

    Generate sample data objects

    my $onedata = $generator->one();

    or
    
    my $onedata = $generator->one({"user_id" => 3});

=cut

sub one {
    my $self = shift;
    my %opt = @_;
    my $obj = {};
    foreach my $key (keys %{$self->{template}}){
        if(exists $opt{$key}){
            $obj->{$key} = $opt{$key};
        }elsif(ref ($self->{template}{$key}) eq 'CODE'){
            $obj->{$key} = $self->{template}{$key}();
        }else{
            $obj->{$key} = $self->{template}{$key};
        }
    }
    return $obj;
}

=head3 C<< $generator->gen( $num ) :ArrayRef >>

    Generate sample data objects

    my $data = $generator->gen(1000);

=cut

sub gen {
    my $self = shift;
    my $num = shift || $self->{num};

    my $res = [];

    while($num-- > 0){
        push @$res, $self->one();
    }
    return $res;
}

=head3 C<< $generator->pat( $num ) :ArrayRef >>

    Generate sample data objects by all pattern

    my $data = $generator->pat({"user_id" => [1, 2], "type" => ["hoge", "fuga", "piyo"]});

    on above samples:
    
    { "user_id" => 1, "type" => "hoge", ...}
    { "user_id" => 2, "type" => "hoge", ...}
    { "user_id" => 1, "type" => "fuga", ...}
    { "user_id" => 2, "type" => "fuga", ...}
    { "user_id" => 1, "type" => "piyo", ...}
    { "user_id" => 2, "type" => "piyo", ...}

=cut

sub pat {
    my $self = shift;
    my $pat = shift;

    croak "pat is required" unless $pat;

    my $res = [];

    my $cmb = undef;
    my $init_key = undef;
    foreach my $key (keys %$pat){
        if(!defined $cmb){
            $cmb = $pat->{$key};
            $init_key = $key;
        }else{
            $cmb = _product($init_key, $cmb, $key, $pat->{$key});
            $init_key = undef;
        }
    }

    foreach my $p (@$cmb){
        push @$res, $self->one(%$p);
    }
    
    return $res;
}

sub _product {
    my ($lname, $lpat, $rname, $rpat) = @_;

    my $prod = [];
    my $obj;
    foreach my $l (@$lpat){
        foreach my $r (@$rpat){
            $obj = {};
            print "$lname, $rname\n";
            if(defined $lname and defined $rname){
                print "$lname, $rname\n";
                $obj->{$lname} = $l;
                $obj->{$rname} = $r;
            }elsif(!defined $lname and defined $rname){
                $obj->{$rname} = $r;
                foreach my $k (keys %$l){
                    $obj->{$k} = $l->{$k};
                }
            }elsif(defined $lname and !defined $rname){
                $obj->{$lname} = $l;
                foreach my $k (keys %$r){
                    $obj->{$k} = $r->{$k};
                }
            }else{
                foreach my $k (keys %$l){
                    $obj->{$k} = $l->{$k};
                }
                foreach my $k (keys %$r){
                    $obj->{$k} = $r->{$k};
                }
            }
            push @$prod, $obj;
        }
    }
    return $prod;
}

=head1 AUTHOR

muddydixon, C<< <muddydixon@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nifty-nirvana-samplegen at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=NIFTY-Nirvana-SampleGen>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::ObjectGenerator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=NIFTY-Nirvana-SampleGen>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/NIFTY-Nirvana-SampleGen>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/NIFTY-Nirvana-SampleGen>

=item * Search CPAN

L<http://search.cpan.org/dist/NIFTY-Nirvana-SampleGen/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 muddydixon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::ObjectGenerator
