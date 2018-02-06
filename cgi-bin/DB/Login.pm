package DB::Login;
## Manage a loagin Storage :
##   require DB::Login;
##   DB::Login::make($dbh); # dbh is handle of database where 
##                          # you would like to store login table
##   .. other DB::Login::* calls
## Depends on : DB::User?

use DBI;
#use DB::User;
use DB::Tools;
use strict;

## creates a new user
## Ret: 0 : all ok
##      1 : id already in use
sub DB::Login::add
{
   my($id, $passwd) = @_;
   ## First check if this id is already in use
   return 1
      if DB::Tools::val_exists($DB::User::dbh, 'LOGIN', 'id', $id);

   my($stmnt) = 'INSERT INTO LOGIN ' .
                '(id, password, password_temp) ' .
                'VALUES (' . $DB::Login::dbh->quote($id) . ', ' .
                             $DB::Login::dbh->quote($passwd) . ', 1)';

   $DB::Login::dbh->do($stmnt) || die "DB::Login::add() : $stmnt : " .
                                      $DB::Login::dbh->errstr;
   return 0;
}

sub temp_password
{
   my($id) = shift;
   if (DB::Tools::val_exists($DB::Login::dbh, 'LOGIN', 'id', $id,
                   'password_temp = 1') == 1)
   {
      return 1;
   }
   return 0;
}

## checks login information
## Ret : 0 : all ok
##       1 : OK but temporary password
##      -1 : id does not exist
##      -2 : incorrect password
sub DB::Login::logon
{
   my($id, $passwd) = @_;
   if (DB::Tools::val_exists($DB::Login::dbh, 'LOGIN', 'id', $id) != 1)
   {
      return -1;
   }
   if (DB::Tools::val_exists($DB::Login::dbh, 'LOGIN', 'id', $id,
                   'password = ' . $DB::Login::dbh->quote($passwd) ) != 1)
   {
      return -2;
   }
   # temporary password
   if (temp_password($id) == 1)
   {
      return 1;
   }
   return 0;
}

sub  DB::Login::get_password
{
   my($id) = shift;
   return DB::Tools::get_val($DB::Login::dbh, 'LOGIN', 'password', 'id = ' .
                             $DB::Login::dbh->quote($id));
}

sub DB::Login::change_password
{
   my($id, $new_passwd, $temp) = @_;
   my($stmnt) = 'UPDATE LOGIN SET password = ' .
                $DB::Login::dbh->quote($new_passwd) . ' ';
   $stmnt .= ", password_temp = $temp " if $temp ne '';
   $stmnt .= 'WHERE id = ' . $DB::Login::dbh->quote($id);
   $DB::Login::dbh->do($stmnt) || die "Could not $stmnt " .
                                      $DB::Login::dbh->errstr;
}

sub DB::Login::setDB
{
   my($dbh) = shift;
   $DB::Login::dbh = $dbh;
}

sub DB::Login::make
{
   my($dbh) = shift;

my $loginCreate = <<'SQL_LOGIN';
CREATE TABLE IF NOT EXISTS LOGIN (
   id VARCHAR(255) NOT NULL PRIMARY KEY, -- maybe be an email address
   password VARCHAR (16) NOT NULL,
   password_temp TINYINT
);
SQL_LOGIN

   DB::Tools::sdo($dbh, $loginCreate);
   ## set dbh
   setDB($dbh);
}


1;
