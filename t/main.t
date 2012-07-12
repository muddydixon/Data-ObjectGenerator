#!perl -T
use Test::More 'no_plan';
use Data::Dumper;

use Data::ObjectGenerator;
use Data::ObjectGenerator::Template;


############################################################
#
# create Template
#
my $now = time;
my $Tmp = Data::ObjectGenerator::Template;

my $template = {
    "user_id" => $Tmp->Number(50, 100),
    "user_name" => $Tmp->String('Cccnnnnn'),
    "time" => $Tmp->Number($now - 3600 * 24 * 7, $now),
    "type" => $Tmp->Enum('hoge', 'fuga', 'piyo'),
    "tag" => "test.sample",
    "register_hour" => $Tmp->Number(1341367130, 1341971912, 3600),
    "gender" => $Tmp->Enum('man', 'woman'),
    "average" => $Tmp->Number(100, 500, undef, 1),
};

sub one_test {
    my $o = shift;
    is(ref $o, 'HASH', 'type check');

    # specific value check
    is($o->{tag}, "test.sample");

    # Number check
    cmp_ok($o->{user_id}, '>=', 50, 'check min');
    cmp_ok($o->{user_id}, '<=', 100, 'check max');

    # String check
    like($o->{user_name}, qr/^[A-Z][a-z]{2}\d{5}$/, 'check string');

    # Enum check
    ok($o->{type} eq 'hoge' or $o->{type} eq 'fuga' or $o->{type} eq 'piyo');

    # Number round check
    cmp_ok($o->{register_hour}, '>=', 1341367130, 'check time min');
    cmp_ok($o->{register_hour}, '<=', 1341971912, 'check time max');
    ok(($o->{register_hour} % 3600) == 0, 'check time round');

    # Number programable check
    cmp_ok($o->{time}, '>=', $now - 3600 * 24 * 7);
    cmp_ok($o->{time}, '<=', $now);
    
    # Enum programable check
    ok($o->{gender} eq "man" or $o->{gender} eq "woman" or $o->{gender} eq "male" or $o->{gender} eq "female" or $o->{gender} eq "unknown");
}
############################################################
#
# create instance
#
my $sample = Data::ObjectGenerator->new(template => $template);

############################################################
#
# check one
#
my $obj = $sample->one;
one_test($obj);

$obj = $sample->one(tag => "hoge");
is($obj->{tag}, "hoge");

############################################################
#
# check gen method
#
my $data = $sample->gen(10);
is(scalar @$data, 10, 'gen test (10)');
foreach my $d (@$data){
    one_test($d);
}

$data = $sample->gen(100);
is(scalar @$data, 100, 'gen test (100)');
foreach my $d (@$data){
    one_test($d);
}


############################################################
#
# check pat method
#
$template = {
    "area_id" => $Tmp->Number(1, 20),
    "mission_id" => $Tmp->Number(1, 30),
    "count" => $Tmp->Number(300, 1000),
};

$sample = Data::ObjectGenerator->new(template => $template);
$data = $sample->gen(100);
is(scalar @$data, 100);

$data = $sample->pat({
    "area_id" => [1, 2, 3, 4, 5, 6],
    "mission_id" => [1, 2, 3, 4, 5, 6, 7, 8, 9]
                        });
is(scalar @$data, 54);

foreach my $d (@$data){
    cmp_ok($d->{area_id}, '>=', 1);
    cmp_ok($d->{area_id}, '<=', 6);

    cmp_ok($d->{mission_id}, '>=', 1);
    cmp_ok($d->{mission_id}, '<=', 9);
}

############################################################
#
# check template from file
#
$sample = Data::ObjectGenerator->new(file => "./sample.json");
$data = $sample->one();
one_test($data);

1;
