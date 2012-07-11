use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::ObjectGenerator',
    AUTHOR              => q{muddydixon <muddydixon@gmail.com>},
    VERSION_FROM        => 'lib/Data/ObjectGenerator.pm',
    ABSTRACT_FROM       => 'lib/Data/ObjectGenerator.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-ObjectGenerator-*' },
);
