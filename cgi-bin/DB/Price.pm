package DB::Price;

use DBI;
use DB::Tools;

sub add
{
   my($rPrice) = shift;

   my($stmnt) = 'INSERT INTO PRICE ' .
                '(UPC, price, storeCode, startDate, endDate, note) ' .
                'VALUES (' .
                $DB::Price::dbh->quote($$rPrice{'UPC'}) . ',' .
                DB::Tools::dbval($$rPrice{'price'}) . ',' .
                DB::Tools::dbval($$rPrice{'storeCode'}) . ',' .
                DB::Tools::dbval($$rPrice{'startDate'}) . ',' .
                DB::Tools::dbval($$rPrice{'endDate'}) . ',' .
                $DB::Price::dbh->quote($$rPrice{'note'}) .
                ')';

   $DB::Price::dbh->do($stmnt)
      || die "Could not add price : $stmnt (" . $DB::Price::dbh->errstr . ")\n";
}

sub get
{
   my($rprice) = shift;
   my($stmnt) = 'SELECT * FROM PRICE WHERE UPC like ' .
                $DB::Price::dbh->quote("%" . $$rprice{'UPC'} . "%");
   my($rprices) = $DB::Price::dbh->selectall_hashref($stmnt, 'UPC')
   || die "Could not get price : $stmnt (" . $DB::Price::dbh->errstr . ")\n";;
   return $$rprices{$$rprice{'UPC'}};
}

sub del
{
   my $rprice = shift;
   my $stmnt =
   'DELETE FROM PRICE WHERE UPC = ' . $DB::Price::dbh->quote($$rprice{'UPC'});
   $DB::Price::dbh->do($stmnt)
   || die "Could not del price : $stmnt (" .  $DB::Price::dbh->errstr . ")\n";

}

sub setDB
{
   my $dbh  = shift;
   $DB::Price::dbh = $dbh;
}

sub make
{
   my $dbh  = shift;
$priceCreate = <<'SQL_PRICE';
CREATE TABLE IF NOT EXISTS PRICE (
   UPC VARCHAR(20) UNIQUE NOT NULL,
   price FLOAT NOT NULL,
   storeCode SMALLINT,
   startDate DATE,
   endDate DATE,
   note VARCHAR(255),
   updateDate TIMESTAMP
);
SQL_PRICE
   @DB::Price::fields = ('UPC', 'price', 'storeCode');
   DB::Tools::sdo($dbh, $priceCreate);
   setDB($dbh);

}

1;
