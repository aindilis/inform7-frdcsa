#!/usr/bin/perl -w

use BOSS::Config;
use PerlLib::SwissArmyKnife;
use System::Inform7;

$specification = q(
	-p <package>		Package to compile
	-m <machine>		Machine type to use

	--verbose		Verbose
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;

die "Error: no package found\n" unless (exists $conf->{'-p'} and -d $conf->{'-p'});

my $i7 = System::Inform7->new
  (
   Package => $conf->{'-p'},
   Machine => $conf->{'-m'} || 'glulx',
  );

my $res = $i7->Compile();
if (exists $conf->{'--verbose'}) {
  print Dumper($res);
}
