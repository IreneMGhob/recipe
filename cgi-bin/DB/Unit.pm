package DB::Unit;

use DBI;
use DB::Tools;

$unitsCreate = <<'CRE';
DROP TABLE UNITS;
CREATE TABLE UNITS (
code SMALLINT NOT NULL PRIMARY KEY,
unit VARCHAR(20) NOT NULL
);
INSERT INTO UNITS (code, unit) VALUES (1, '');
INSERT INTO UNITS (code, unit) VALUES (2, 'g');
INSERT INTO UNITS (code, unit) VALUES (3, 'kg');
INSERT INTO UNITS (code, unit) VALUES (4, 'ml');
INSERT INTO UNITS (code, unit) VALUES (5, 'cup');
INSERT INTO UNITS (code, unit) VALUES (6, 'teaspoon');
INSERT INTO UNITS (code, unit) VALUES (7, 'tablespoon');
INSERT INTO UNITS (code, unit) VALUES (8, 'oz');
INSERT INTO UNITS (code, unit) VALUES (9, 'lb');
INSERT INTO UNITS (code, unit) VALUES (10, 'L');
CRE

sub get
{
   my $code;
   my %units; ## hash with keys = unit and value = code
   my($stmnt) = 'SELECT * FROM UNITS';
   $stmnt .= ' WHERE code = $code' if $code;

   my $sth = $DB::Units::dbh->prepare($stmnt);
   $sth->execute()
      || die "Could not get unit: $stmnt (" . $DB::Units::dbh->errstr . ")\n";
   my (@row);
   while (@row = $sth->fetchrow_array )
   {
      $units{$row[0]} = $row[1];
#      $units{$row[1]} = $row[0];
   }
   return \%units;
}


sub setDB
{
   $DB::Units::dbh = shift;
}

sub make
{
   my $dbh = shift;
   DB::Tools::sdo($dbh, $unitsCreate);
   setDB($dbh);
}

