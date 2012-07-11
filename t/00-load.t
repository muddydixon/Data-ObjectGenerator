#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::ObjectGenerator' ) || print "Bail out!\n";
}

diag( "Testing Data::ObjectGenerator $Data::ObjectGenerator::VERSION, Perl $], $^X" );
