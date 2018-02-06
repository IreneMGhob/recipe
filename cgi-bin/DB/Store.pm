package DB::Store;
# package to handle storage of stores
use DBI;
use DB::Tools;


sub add
{
   my($rStore) = shift; # reference to hash containing data
#   my($name, $desc, $city, $prov, $postal, $int_code, $type_code) = @_;

   my($stmnt) = 'INSERT INTO STORE ' .
                '(name, description, city, provinceCode,' .
                ' postalCode, internalCode, typeCode) ' .
                'VALUES (' .
                $DB::Store::dbh->quote($$rStore{'name'}) . ',' .
                $DB::Store::dbh->quote($$rStore{'description'}) . ',' .
                $DB::Store::dbh->quote($$rStore{'city'}) . ',' .
                $DB::Store::dbh->quote($$rStore{'provinceCode'}) . ',' .
                $DB::Store::dbh->quote($$rStore{'postalCode'}) . ',' .
                $DB::Store::dbh->quote($$rStore{'internalCode'}) . ',' .
                DB::Tools::dbval($$rStore{'typeCode'}) .
                ')';
   $DB::Store::dbh->do($stmnt)
   || die "Could not add store : $stmnt (" .  $DB::Store::dbh->errstr . ")\n";

}

sub get
{
   my($rStore) = shift; # reference to hash containing data
   my $stmnt  = 'SELECT * FROM STORE ';
   my @where;
   push(@where, 'name REGEXP ' .
                $DB::Store::dbh->quote($$rStore{'name'}))
      if $$rStore{'name'};

   push(@where, 'city like ' .
                $DB::Store::dbh->quote('%' . $$rStore{'city'} . '%'))
      if $$rStore{'city'};

   push(@where, 'provinceCode like ' .
                $DB::Store::dbh->quote('%' . $$rStore{'provinceCode'} . '%'))
      if $$rStore{'provinceCode'};

   my $where = 'WHERE ' . join(' AND ' , @where) if $#where > -1;
   $stmnt .= $where if $where;
   my($rStores) = $DB::Store::dbh->selectall_hashref($stmnt, 'code') ||
                    die("Could not get stores ($stmnt) : " .
                    $DB::Store::dbh->errstr);
   return $rStores;

} # get()


sub get_types
{
   my($rRowArry) = DB::Tools::get_all_arrayref($DB::Store::dbh, 'STORE_TYPES');
   my(%types, $rType);
   foreach $rType (@$rRowArry)
   {
      $types{$$rType[0]} = $$rType[1];
   }
   return %types;
}

sub setDB
{
   my($dbh) = shift;
   $DB::Store::dbh = $dbh;
}

sub make
{
$storeTypesCreate = <<'SQL_TYPES';
DROP TABLE STORE_TYPES;
CREATE TABLE IF NOT EXISTS STORE_TYPES (
   code SMALLINT NOT NULL,
   name VARCHAR(80) NOT NULL
);
INSERT INTO STORE_TYPES (name, code) VALUES ('Grocery', 1);
INSERT INTO STORE_TYPES (name, code) VALUES ('Department', 2);
INSERT INTO STORE_TYPES (name, code) VALUES ('Wholesale', 3);
SQL_TYPES

$storeCreate = <<'SQL_SHOPS';
CREATE TABLE IF NOT EXISTS STORE (
   code SMALLINT AUTO_INCREMENT PRIMARY KEY,
   name VARCHAR(80),
   description VARCHAR(200),
   city VARCHAR(50),
   provinceCode VARCHAR(3),
   postalCode VARCHAR(9),
   internalCode VARCHAR(9), -- if any
   typeCode SMALLINT
);
SQL_SHOPS

   ## Keep an array of fields for those interested in knowing
   ## same order as fields in DB table
   ## code is auto so it need not be included ??
   @DB::Store::fields =
   ('name', 'description', 'city', 'provinceCode', 'InternalCode', 'typeCode');

   my($dbh) = shift;
   setDB($dbh);
   DB::Tools::sdo($DB::Store::dbh, $storeTypesCreate);
   DB::Tools::sdo($DB::Store::dbh, $storeCreate);
}

1;
