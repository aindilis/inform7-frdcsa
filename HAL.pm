package HAL;

use Moose;

use HAL::NineThousand;

use BOSS::Config;
use MyFRDCSA;
use PerlLib::SwissArmyKnife;

has Config =>
  (
   is => 'rw',
   isa => 'BOSS::Config',
  );

has NineThousand =>
  (
   is => 'rw',
   isa => 'HAL::NineThousand',
  );

sub BUILD {
  my ($self,$args) = @_;
  my %args = %$args;
  my $specification = "
	-p <package>		Package to use to run Hal

	-u [<host> <port>]	Run as a UniLang agent

	-w			Require user input before exiting
";
  $UNIVERSAL::agent->DoNotDaemonize(1);
  # $UNIVERSAL::systemdir = ConcatDir(Dir("internal codebases"),"hal");
  $self->Config
    (BOSS::Config->new
     (Spec => $specification,
      ConfFile => ""));
  my $conf = $self->Config->CLIConfig;
  if (exists $conf->{'-u'}) {
    $UNIVERSAL::agent->Register
      (Host => defined $conf->{-u}->{'<host>'} ?
       $conf->{-u}->{'<host>'} : "localhost",
       Port => defined $conf->{-u}->{'<port>'} ?
       $conf->{-u}->{'<port>'} : "9000");
  }
  print "Hi Dog\n";
  print Dumper({Package => $conf->{'-p'}});
  $self->NineThousand
    (HAL::NineThousand->new
     ({
       Package => ($conf->{'-p'} || ""),
      }));
}

sub Execute {
  my ($self,%args) = @_;
  my $conf = $self->Config->CLIConfig;
  if (exists $conf->{'-u'}) {
    # enter in to a listening loop
    while (1) {
      $UNIVERSAL::agent->Listen(TimeOut => 10);
    }
  }
  if (exists $conf->{'-w'}) {
    Message(Message => "Press any key to quit...");
    my $t = <STDIN>;
  }
}

sub ProcessMessage {
  my ($self,%args) = @_;
  my $m = $args{Message};
  print Dumper($m);
  my $it = $m->Contents;
  if ($it) {
    if ($it =~ /^init$/i) {
      print "Initializing HAL\n";
      my $results = $self->NineThousand->ProcessUserCommand
	({
	  Command => 'l',
	 });
    } elsif ($it =~ /^Hal,/i) {
      my $inputcopy = $it;
      $inputcopy =~ s/^Hal,\s*//sgi;
      print Dumper({Input => $inputcopy});
      my $results = $self->NineThousand->ProcessUserCommand
	({
	  Command => $inputcopy,
	 });
      $UNIVERSAL::agent->QueryAgentReply
	(
	 Message => $m,
	 Data => {
		  _DoNotLog => 1,
		  Results => $results,
		 },
	);
    } elsif ($it =~ /^echo\s*(.*)/) {
      $UNIVERSAL::agent->SendContents
	(Contents => $1,
	 Receiver => $m->{Sender});
    } elsif ($it =~ /^(quit|exit)$/i) {
      $UNIVERSAL::agent->Deregister;
      exit(0);
    }
  }
  # if (exists $m->Data->{Command}) {
  # }
}

1;
