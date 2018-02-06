package Log;

## log utilities

$main::logFile = 'content.log'; # default log file
$main::logDir = './log'; # default lof dir

sub setLogDir
{
   $main::logDir = shift;
}

sub setLogFile
{
   $main::logFile = shift;
}

sub log
{
   my ($string) = @_;
   mkdir $main::logDir if ! -d $main::logDir;
   my $access_fpath = $main::logDir . '/' . $main::logFile;
   open (logFH, ">>$access_fpath") || die "Cannot open $main::logFile\n";
   print logFH $string . "\n";
   close logFH;
}


1;
