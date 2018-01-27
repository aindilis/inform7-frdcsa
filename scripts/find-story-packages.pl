#!/usr/bin/perl -w

use BOSS::Config;
use KBS2::Util;
use PerlLib::SwissArmyKnife;

$specification = q(
	-r		Rescan
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
# $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/system";


my $datadir = '/var/lib/myfrdcsa/codebases/minor/inform7-frdcsa/data';
my $datafile = $datadir.'/stories.dat';
if (! -f $datafile or exists $conf->{'-r'}) {
  my @packages;
  my $locateres = `locate -r '\\.ni\$'`;
  foreach my $file (split /\n/, $locateres) {
    if ($file =~ /^(.+)\/Source\/[^\/]+\.ni$/) {
      push @packages, $1;
    }
  }
  write_file_dumper(File => $datafile, Data => \@packages);
}
if (-f $datafile) {
  my $res = read_file_dedumper($datafile);
  print PerlDataStructureToStringEmacs(DataStructure => $res);
} else {
  die "No datafile $datafile\n";
}
