#!/usr/bin/perl -w

## CGI Program that reads html and replace any [elements] recursively.
## The default file it reads is index.html.
## The elements that it processes are :
##
## HTML element
## -----------------
## [include <html_element>]
## where <html_element> is an actual file (currently in the curr dir)
## the include has to be on a line by itself
##
## CGI Variable element
## ----------------------
## [CGI var]
## it would replace this string with $q->param('var') if exists
##
## perl element
## --------------
## [perl]
## <perl code>
## [/perl]
## The perl code can use the exsiting CGI $q var
##
## ---------------------------------------------------
## Configuration file
## --------------------
## Configuration file should be in the same directory as this cgi
## and it is called content.cfg
## It has the syntax <var> <val> each on a separate line
## Mandatory fields in content.cfg are 
## ELEMENTS_PATH : where to look for elements
## 
## content.cgi specific CGI Variables 
## ----------------------------------
## 'content' later I need to find out how to do it neatly :
## content.cgi/<file> instead of content.cgi?content=<file>
## 'header' : extra header info ???
##

use strict;
use CGI qw/:standard -debug/;

## Global variables
$main::parsed = ''; ## parsed html
$main::outFile = '/tmp/content.' . $$; ## temporary file for parsing
%main::file = ''; ## file to be parsed

sub parseCFG
{
   open CH, 'content.cfg';
   my @varVal;
   my $var;
   while (<CH>)
   {
      @varVal = split(' ', $_);
      $var = shift(@varVal);
      $main::cfg {$var} = join(' ', @varVal);
   }
   close CH;
   ## do the stuff that we need to do after parsing variable
   ## change to ELEMENTS_PATH
   my $path = $main::cfg{'ELEMENTS_PATH'};
   chdir($path) || print "ERROR : bad ELEMENTS_PATH $path\n";
}

sub parseElements
{
   my ($q, $line) = @_;
   $_ = $line;
   if ( /\[include (.*)\]/g )
   {
      rprwFile($q, $1);
   }
   elsif ( /\[CGI (.*)\]/g )
   {
      my $parm = $q->param($1);
      if ($parm)
      {
         $line =~ s/\[CGI .*\]/$parm/;
         $main::parsed .= $line;
      }
   }
   else
   {
      $main::parsed .= $line;
   }
} # parseElements()

## run any perl code
sub runPerl
{
   my($file, $content) = @_;
   my($out);
   my $perlCode;
   ## use /s (at end) to parse the multiline string
   while ($content =~ /(.*?)\[perl\](.*?)\[\/perl\]/sg)
   {

      print $1 if ($1);
      if ($2)
      { 
         $perlCode = $2;
         eval $perlCode;
         if ($@)
         {
            die 'ERROR in ' . $file .
                  "<BR>RETURN : $@<BR>---------------------------------<BR>" .
                  'SYNTAX ERROR IN <BR>--------------------------' .
                  "<PRE>$perlCode</PRE><BR>" .
                  "---------------------------------<BR>\n";
         }
      }
   }

   ## print everything after last [/perl] if exists
   $content =~  /(.*\[\/perl\])*(.*)$/s;
   my $rest = $2;
   print $rest if ($rest);
   print $content if (!$rest);
} # runPerl


## Reads <file>, Parses it, Replaces compnonents and Writes it to standard
## output when it has no more elements
sub rprwFile
{
   my ($q, $file) = @_;
   local (*FH);
   if (!open FH, $file)
   {
      die "ERROR : element file \"$main::cfg{'ELEMENTS_PATH'}$file\" missing\n";
   }

   ## get includes
   while (<FH>)
   {
      parseElements($q, $_);
   }
   close FH;

} # rprwFile()


########### MAIN ##################

## parse cfg file

parseCFG();

open my $oldout, ">&STDOUT"     or die "Can't dup STDOUT: $!";
open STDOUT, '>', $main::outFile 
|| die ("Couldn't redirect standard output to $main::outFile: $!");

select STDOUT; $| = 1;      # make unbuffered


$main::q = new CGI;

if ($main::q->param('content'))
{
   $main::file = $main::q->param('content');
}
else
{
   $main::file = 'index.html';
}

rprwFile($main::q, $main::file);


runPerl($main::file, $main::parsed);

## redirect back stdout
close STDOUT;
open STDOUT, ">&", $oldout or die "Can't dup \$oldout: $!";


## print header only if it was not already included in one of the
## parsed elements
## so first check if there is the baseic header
my $hdr = $main::q->header();
chop $hdr;
chop $hdr;
my $isHdr = 0;
open OH, $main::outFile || die "Could not open $main::outFile : $!\n";
while (<OH>)
{
   $isHdr = 1 if /$hdr/;
   last if $isHdr;
}
close OH;

# now print to STDOUT
print "$hdr\n\n" if (!$isHdr);
open OH, $main::outFile || die "Could not open $main::outFile : $!\n";
while (<OH>)
{
   print $_;
}
close OH;
unlink $main::outFile;
