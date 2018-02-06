package DB::Tools;

use DBI;

$PKG = 'DB::Tools::';


## prepares a value for being inserted into db
## if it's not set then return NULL
sub dbval
{
   my($v) = @_;

   if (! $v || $v eq '')
   {
      return 'NULL';
   }
   else
   {
      return $v;
   }
}

## checks if a specific table column exists with a specific value
sub val_exists
{
   my($dbh, $table, $column, $value, $where) = @_;
   ## ?? would it match if column is not a string ??!!
   my $stmnt = 'SELECT count(1) FROM ' . $table . ' WHERE ' . $column .
               ' = ' . $dbh->quote($value);
   $stmnt .= ' AND ' . $where if $where && $where ne '';
   my $ary_ref = $dbh->selectall_arrayref($stmnt)
      || die "val_exists() : Could not selectall_arrayref ($stmnt):" .
             $dbh->errstr . ")\n";;
   return $ary_ref->[0]->[0]
}

## gets a specific table column for a row with a specific value
sub get_val
{
   my($dbh, $table, $column, $where) = @_;
   ## ?? would it match if column is not a string ??!!
   my $stmnt = 'SELECT ' . $column . ' FROM ' . $table;
   $stmnt .= ' WHERE ' . $where if $where && $where ne '';
   my $ary_ref = $dbh->selectall_arrayref($stmnt)
      || die "val_exists() : Could not selectall_arrayref ($stmnt):" .
             $dbh->errstr . ")\n";;
   return $ary_ref->[0]->[0]
}

## runs multiple sql statements sparated by ; that may have comments (--)
sub sdo
{
   my($dbh, $str) = @_;

   # get rid of comments
   $str =~ s/--.*\n//g;
   # get rid of \n
   $str =~ s/\n//g;
   my(@stmnts) = split(/;/, $str);
   my($st);
   foreach $st (@stmnts)
   {
      $dbh->do($st) || die 'Error (' . $st . ') - ' . $dbh->errstr;
   }
}

## gets all contents of a table in an array
sub get_all_arrayref
{
   my($dbh, $table) = @_;
   my($stmnt) = 'SELECT * FROM ' . $table;

   my($rRowArry) = $dbh->selectall_arrayref($stmnt)
     || die "Could not selectall for $table : $stmnt (" . $dbh->errstr .  ")\n";
   return $rRowArry;
}

## gets certain columns of a table in an array
sub get_cols_arrayref
{
   my($dbh, $table, @cols) = @_;
   my($stmnt) = 'SELECT DISTINCT ';
   $stmnt .= join(',', @cols);
   $stmnt .= ' FROM ' . $table;

   my($rRowArry) = $dbh->selectall_arrayref($stmnt)
     || die "Could not selectall for $table : $stmnt (" . $dbh->errstr .  ")\n";
   return $rRowArry;
}

1;
