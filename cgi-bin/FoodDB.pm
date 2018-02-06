package FoodDB;

use DBI;

#print "DBI Version : $DBI::VERSION;\n";

sub FoodDB::connect
{
   my($username, $password) = @_;
   
   $FoodDB::dbh = DBI->connect($FoodDB::dataSource, $username, $password) ||
     print "Can't connect to $FoodDB::dataSource $FoodDB::dbh->errstr\n";
   return $FoodDB::dbh;
}

sub FoodDB::do
{
   my($stmnt) = @_;
   $FoodDB::dbh->do($stmnt);
#$code = $foodDB::dbh->last_insert_id(undef, undef, 'RECIPES', 'code');
#my $code = $foodDB::dbh->last_insert_id();
#if ($code == undef)
#{
#print "ERROR can't get code " . $foodDB::dbh->errstr . "\n";
#}
#print "CODE : $code\n";
#$code = $foodDB::dbh->do('SELECT LAST_INSERT_ID()');
#print "CODE : $code\n";

}

sub FoodDB::disconnect
{
   $FoodDB::dbh->disconnect();
}


BEGIN
{
   $FoodDB::dataSource = 'DBI:mysql:elinkw2_FOOD';
   $FoodDB::username = 'elinkw2_food1';

   $FoodDB::dbh = FoodDB::connect($FoodDB::username, 'food2017');
   ## if tables are not already there create them
   use FoodDB::Admin;
   FoodDB::Admin::make($FoodDB::dbh);
}

1;
