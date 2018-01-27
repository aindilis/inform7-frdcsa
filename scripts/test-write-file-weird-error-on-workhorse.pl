#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;

my @packages = split /\n/, `ls -1`;
write_file_dumper(File => '/tmp/wtf', Data => \@packages);
