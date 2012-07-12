Data-ObjectGenerator

======

INSTALLATION

Get from github

  git clone git://github.com/muddydixon/Data-ObjectGenerator.git
  cd Data-ObjectGenerator

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

Then try below command

	$ perl ./bin/datagen.pl -t sample.json -n 3 -f fluentd

And execute plan to create in some formats and output some storage

Start mysqld

  $ mysqld
  $ mysql test < example/mysql.sql

Start mongodb

  $ mkdir example/mongo
  $ mongod -f example/mongod.conf

Start fluentd

  $ fluentd -c example/fluentd.conf

Exec

	$ perl ./bin/datagen.pl -p plan.sample.json

Execute above, write data
  1. to file ./payment.log,
  2. to stdout on csv format,
  3. to stdout on fluentd format,
  4. to fluentd forwarding,
  5. to mongod
  6. to mysql

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Data::ObjectGenerator

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-ObjectGenerator

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Data-ObjectGenerator

    CPAN Ratings
        http://cpanratings.perl.org/d/Data-ObjectGenerator

    Search CPAN
        http://search.cpan.org/dist/Data-ObjectGenerator/


LICENSE AND COPYRIGHT

Copyright (C) 2012 muddydixon

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

