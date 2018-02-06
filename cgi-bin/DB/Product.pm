package DB::Product;

use DBI;
use DB::Tools;
use strict;

## generates a product id
sub getPID
{
   my $maxpid = DB::Tools::get_val($DB::Product::dbh, 'PRODUCT', 'MAX(UPC)',
                                   'UPC like ' .
                                   $DB::Product::dbh->quote("PID%"));
   $maxpid = 'PID00000000'
      if !$maxpid && $maxpid eq ''; ## first PID to generate
   $maxpid ++;
   return $maxpid;
}

# Retu: Error message or empty string if all ok
sub add
{
   my($rproduct) = shift; ## this either a product ref or the UPC of a prod
   my($upc, $name, $desc, $mk, $qty, $unit, $inc);
   if ($#_ > -1) ## fields
   {
      ($name, $desc, $mk, $qty, $unit, $inc) = @_;
      $upc = $rproduct;
   }
   else
   {
      $upc = $$rproduct{'UPC'};
      $name = $$rproduct{'name'};
      $desc = $$rproduct{'description'};
      $mk = $$rproduct{'make'};
      $qty  = $$rproduct{'quantity'};
      $unit = $$rproduct{'unit'};
      $inc = $$rproduct{'increment'};
   }

   ## first check that this product (UPC) does not exist
   return '', 'UPC ' . $upc . ' already exists' 
      if $upc ne '' &&
         DB::Tools::val_exists($DB::Product::dbh, 'PRODUCT', 'UPC', $upc);

   ## if product does not have a UPC then generate a product ID (PID)
   $upc = getPID() if !$upc || $upc eq '';

   ## if any of 'NOT NULL' fields are empty return message
   return '', 'Name is required.' if $name eq '';

   my($stmnt) = 'INSERT INTO PRODUCT ' .
                '(UPC, name, description, make, quantity, unit, increment) ' .
                'VALUES (' .
                $DB::Product::dbh->quote($upc) . ',' .
                $DB::Product::dbh->quote($name) . ',' .
                $DB::Product::dbh->quote($desc) . ',' .
                $DB::Product::dbh->quote($mk) . ',' .
                DB::Tools::dbval($qty) . ',' .
                $DB::Product::dbh->quote($unit) . ',' .
                DB::Tools::dbval($inc) .
                ')';

   $DB::Product::dbh->do($stmnt)
   || die "Could not add product : $stmnt (" .
          $DB::Product::dbh->errstr . ")\n";
   return $upc, '';
}

sub del
{
   my($rproduct) = shift; ## this either a product ref or the UPC of a prod
   my($upc, $name, $desc, $mk, $qty, $unit);
   if ($#_ > -1) ## fields
   {
      ($name, $desc, $mk, $qty, $unit) = @_;
      $upc = $rproduct;
   }
   else
   {
      $upc = $$rproduct{'UPC'};
      $name = $$rproduct{'name'};
      $desc = $$rproduct{'description'};
      $mk = $$rproduct{'make'};
      $qty  = $$rproduct{'quantity'};
      $unit = $$rproduct{'unit'};
   }
   my $stmnt = 'DELETE FROM PRODUCT WHERE UPC = ' .
               $DB::Product::dbh->quote($upc);
   $stmnt .= ' AND name = ' . $DB::Product::dbh->quote($name) if $name;
   $stmnt .= ' AND description = ' . $DB::Product::dbh->quote($desc) if $desc;
   $stmnt .= ' AND make = ' . $DB::Product::dbh->quote($mk) if $mk;
   $stmnt .= ' AND ROUND(quantity,2) = ' . $qty if $qty;
   $stmnt .= ' AND unit = ' . $DB::Product::dbh->quote($unit) if $unit;
   
   $DB::Product::dbh->do($stmnt)
   || die "Could not del product : $stmnt (" .
          $DB::Product::dbh->errstr . ")\n";
             
}

## gets all entries matching values in %product
sub get
{
   my %product  = @_;
   my $stmnt  = 'SELECT * FROM PRODUCT ';
   my @where;
   push(@where, 'name REGEXP ' .
                $DB::Product::dbh->quote($product{'name'}))
      if $product{'name'};
   push(@where, 'UPC = ' .  $DB::Product::dbh->quote($product{'UPC'}))
      if $product{'UPC'};
   push(@where, 'make REGEXP ' .  $DB::Product::dbh->quote($product{'make'}))
      if $product{'make'};
   my $where = 'WHERE ' . join(' AND ' , @where) if $#where > -1;
   $stmnt .= $where if $where;
   my($rproducts) = $DB::Product::dbh->selectall_hashref($stmnt, 'UPC') || 
                    die("Could not get product ($stmnt) : " .
                    $DB::Product::dbh->errstr);
   return $rproducts;
}

sub setDB
{
   my $dbh  = shift;
   $DB::Product::dbh = $dbh;
}

sub make
{
   my $dbh  = shift;
   my $productCreate = <<'SQL_PRODUCTS';
CREATE TABLE IF NOT EXISTS PRODUCT (
   UPC VARCHAR(20) UNIQUE NOT NULL,
   name VARCHAR(80) NOT NULL,
   description VARCHAR(120),
   make VARCHAR (80),
   quantity FLOAT,
   unit VARCHAR (30),
   increment FLOAT,
   updateDate TIMESTAMP
);
SQL_PRODUCTS
   @DB::Product::fields = ('UPC', 'name', 'description', 'make', 'quantity',
                           'unit', 'increment');
#ALTER TABLE PRODUCT ADD INDEX PRODUCT_NAME_INDEX (name);
   DB::Tools::sdo($dbh, $productCreate);
   setDB($dbh);
}

1;
