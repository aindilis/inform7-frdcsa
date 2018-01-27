package HAL::NineThousand;

use PerlLib::SwissArmyKnife;
use System::Inform7::GLULXE;

use Event;
use Moose;

has Debug => ( is => 'rw', isa => 'Int' );
has GLULXE => ( is => 'rw', isa => 'System::Inform7::GLULXE' );
has Package => ( is => 'rw', isa => 'Str' );
has Started => ( is => 'rw', isa => 'Bool' );

our $doppleganger;
our $lastminute = -1;

sub BUILD {
  my ($self,$args) = @_;
  $doppleganger = $self;
  my %args = %{$args || {}};
  print Dumper({Package1 => $args{Package}});
  $self->Package($args{Package});
  $self->GLULXE(System::Inform7::GLULXE->new());
}

sub Start {
  my ($self,$args) = @_;
  my %args = %{$args || {}};

  # we will want to generate the I7 file from the WSM and other
  # sources, compile it, load it

  # alternatively we will want to load a saved GLULXE format file, and
  # replay the last moves.

  print Dumper({Package2 => $args{Package}});
  my $package = $args{Package} || $self->Package;
  print Dumper({Package3 => $package});
  # $package ||= '/var/lib/myfrdcsa/codebases/minor/normal-form/inform7/Normal-Form/Normal Form.inform';
  $package ||= "/var/lib/myfrdcsa/codebases/work/clients/Computing-Workshop/students/2015/Inform7/world/Computing-Workshop-2015/Computing-Workshop-2015.inform";
  my $ulxfile = $package.'/Build/output.ulx';
  print Dumper({ULXFile => $ulxfile});

  my $init = $self->GLULXE->Start
    (
     ULXFile => $ulxfile,
    );

  # start a timer to update the time every minute
  $UNIVERSAL::agent->NewEvent
    (
     Type => 'timer',
     Args => {
	      interval => 1,
	      repeat => 1,
	      cb => sub {CheckTime()},

	     },
    );

  $UNIVERSAL::agent->NewEvent
    (
     Type => 'timer',
     Args => {
	      interval => 5 * 60,
	      repeat => 1,
	      cb => sub {CheckWeather()},

	     },
    );


  $self->Started(1);
  return {
	  Results => $init,
	 };
}

sub CheckTime {
  my @res = (localtime)[1,2];
  # print Dumper(\@res);
  if ($lastminute != $res[0]) {
    my $time = sprintf("%02i", $res[1]).':'.sprintf("%02i", $res[0]),;
    $doppleganger->UpdateClock
      ({
	Time => $time,
       });
  }
  $lastminute = $res[0];
}

sub UpdateClock {
  my ($self,$args) = @_;
  my %args = %{$args || {}};
  # send a command to the I7 VM with the updated time
  my $res = $self->IssueCommandToI7VM
    ({
      From => 'Hal',
      Command => 'set the game clock to '.$args{Time},
     });
  # print Dumper({ClockUpdateRes => $res});
}

sub CheckWeather {
  # query a weather API and return the weather
  # send a command to the I7 VM with the updated weather
  # my $res = $self->IssueCommandToI7VM
  #   ({
  #     From => 'Hal',
  #     Command => 'set the weather to blah blah blah'
  #    });
  # print Dumper({WeatherRes => $res});
}

sub ProcessUserCommand {
  my ($self,$args) = @_;
  my %args = %{$args || {}};

  # first run any preprocessing of the command

  # then run any command hooks

  # then run any I7 commands we need to prepare for this command

  # then run the I7 command through GLULXE

  return $self->IssueCommandToI7VM
    ({Command => $args{Command}});

  # keep a log of the user commands, and the settings in which they are issued.

  # then everything maybe in reverse
}


# sub MainLoop {
#   my ($self,$args) = @_;
#   my %args = %{$args || {}};

#   my $userscommandresponseprocessed;
#   my $halscommandresponseprocessed;
#   my $loop = 1;

#   while ($loop) {

#     $userscommandresponseprocessed = $self->DoUsersCommand
#       ();

#     $halscommandresponseprocessed = $self->DoHalsCommand
#       (UsersCommandResponseProcessed => $userscommandresponseprocessed);

#   }

#   # FIXME: This is all wrong we need a select here, or maybe a unilang
#   # agent.  Also is the computer necessarily hal, or is that the
#   # personality we interact with.

# }

sub IssueCommandToI7VM {
  my ($self,$args) = @_;
  my %args = %{$args || {}};
  my $res0 = {};
  if (! $self->Started) {
    $res0 = $self->Start
      ({Package => $args{Package}});
  }
  my $res1 = $self->GLULXE->IssueCommand(Command => $args{Command});
  print Dumper
    ({
      Command => $args{Command},
      Result => $res1->{Result},
     }) if 0;
  return $res1;
}

# sub DoUsersCommand {
#   my ($self,$args) = @_;
#   my %args = %{$args || {}};

#   my $usercommand = <STDIN>;
#   chomp $usercommand;

#   my $usercommandresponse = $self->IssueCommandToI7VM
#     (Command => $usercommand);

#   return $self->ProcessUsersCommandResponse
#     (UsersCommandResponse => $usercommandresponse);
# }

# sub ProcessHalsCommand {
#   my ($self,$args) = @_;
#   my %args = %{$args || {}};

#   my $halscommand = $self->GenerateHalsCommandFromUsersCommandResponseProcessed
#     (UsersCommandResponseProcessed => $args{UsersCommandResponseProcessed});
#   if ($halscommand->{Success}) {

#     # issue the hal's command
#     my $inform7vmhalscommandsoutputprocessed = $self->IssueCommandToI7VM
#       (Command => $halscommand->{Command});

#     # my $

#   }
# }

1;
