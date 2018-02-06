package DB::User;
## Manage a user Storage :
##   require DB::User;
##   DB::User::make($dbh); # dbh is handle of database where 
##                         # you would like to store user table
##   .. other DB::User::* calls

use DBI;
use DB::Tools;
use strict;

## creates table for use if not exists

## creates a new user
## Ret: 0 : all ok
##      1 : user id already in use
sub DB::User::add
{
   my($id, $fname, $lname, $email) = @_;
   ## First check if this id is already in use
   return 1
      if DB::Tools::val_exists($DB::User::dbh, 'USER', 'id', $id);

   my($stmnt) = 'INSERT INTO USER ' .
                '(id, fname, lname, email) ' .
                'VALUES (' . $DB::User::dbh->quote($id) . ', ' .
                             $DB::User::dbh->quote($fname) . ', ' .  
                             $DB::User::dbh->quote($lname) . ', ' .  
                             $DB::User::dbh->quote($email) . ')';

   $DB::User::dbh->do($stmnt) || die "DB::User::add() : $stmnt : " .
                                     $DB::User::dbh->errstr;
   return 0;
}

sub DB::User::make
{
   my($dbh) = shift;

my $userCreate = <<'SQL_USER';
CREATE TABLE IF NOT EXISTS USER (
   id VARCHAR(255) NOT NULL PRIMARY KEY, -- maybe be an email address
   fname VARCHAR(80) NOT NULL,
   lname VARCHAR (80) NOT NULL,
   email VARCHAR (255) NOT NULL
);
SQL_USER

   DB::Tools::sdo($dbh, $userCreate);
   ## set dbh
   $DB::User::dbh = $dbh;
}


1;
