package FoodDB::Recipe;
## Package that has all Food DB Recipe related functions

use FoodDB;
use DB::Tools;

sub get_last_insert_id
{
## this is a temporary solution should check comp.lang.perl.* for why
## last_insert_id() is not working
   return $FoodDB::dbh->{'mysql_insertid'};
}


## adds a recipe
sub Recipe::add
{
   my($name, $desc, $steps, $calories, $cholestrol,
      $sodium, $carb, $fiber,
      $protein, $fat, $saturatedFat, $prepTime, $cookingTime,
      $yield, $yieldUnit, $country, $source, $creator) = @_;
   my($stmnt) = 'INSERT INTO RECIPES ' .
                '(name, description, steps, calories,' .
                ' cholestrol, sodium,' .
                ' carb, fiber, protein, fat, saturatedFat, prepTime,' .
                ' cookingTime, yield, yieldUnit, country, source, creator,' .
                ' create_dt) ' .
                'VALUES (' . $FoodDB::dbh->quote($name) . ', ' .
                             $FoodDB::dbh->quote($desc) . ', ' .
                             $FoodDB::dbh->quote($steps) . ', ' .
                             DB::Tools::dbval($calories) . ', ' .
                             DB::Tools::dbval($cholestrol) . ', ' .
                             DB::Tools::dbval($sodium) . ', ' .
                             DB::Tools::dbval($carb) . ', ' .
                             DB::Tools::dbval($fiber) . ', ' .
                             DB::Tools::dbval($protein) . ', ' .
                             DB::Tools::dbval($fat) . ', ' .
                             DB::Tools::dbval($saturatedFat) . ', ' .
                             DB::Tools::dbval($prepTime) . ', ' .
                             DB::Tools::dbval($cookingTime) . ', ' .
                             DB::Tools::dbval($yield) . ', ' .
                             $FoodDB::dbh->quote($yieldUnit) . ', ' .
                             $FoodDB::dbh->quote($country) . ', ' .
                             $FoodDB::dbh->quote($source) . ', ' .
                             $FoodDB::dbh->quote($creator) . ', ' .
                             'NOW())';
   FoodDB::do($stmnt)
      || die "Could not add recipe : $stmnt (" . $FoodDB::dbh->errstr . ")\n";
   ## now get the code
   my $code = get_last_insert_id();
   return $code;
}

# gets a recipe
sub get
{
   my($code) = shift;
   my($stmnt) = 'SELECT * FROM RECIPES WHERE code = ' . $code;
   my($rrecipe) = $FoodDB::dbh->selectrow_hashref($stmnt);
   my(%recipe) = %$rrecipe;
   return %recipe;
}


## searches for a recipe in %recipes if available otherwise in DB
## this is so to allow complex searches
sub Recipe::searchByName
{
   my($rName, %recipes) = @_;
   my(%found, $rCode);
   if ($rName ne '')
   {
      if (%recipes)
      {
         foreach $rCode (keys %recipes)
         {
            $_ = $recipes{$rCode};
            $found{$rCode} = $recipes{$rcode} if /$rName/;
         }
      }
      else
      {

         my($stmnt) = $Recipe::searchSelectStr . $Recipe::searchFromStr .
                      ' WHERE name like ' .
                      $FoodDB::dbh->quote('%' . $rName . '%');
         %found = Recipe::getSearchResults($stmnt);
      }
   }
   else
   {
      die('Recipe::searchByName() : No recipe name passed');
   }
   return %found;
}


## searches for recipes that have ingredients
## if rrecipes is passed then it searches for ingredients in these rrecipes
## this allows complex searches
sub Recipe::searchByIngredients
{
   my($rings, $rrecipes) = @_;
   my(@ings) = @$rings;
   die 'Recipe::searchByIngredients() : No Ingredients passed' if $#ings <= -1;
   my(%recipes) = %$rrecipes;
   my(%found);

   my($ingSlct) = ' AND (ingredient =' . $FoodDB::dbh->quote($ings[0]);
   shift @ings;
   my($ing);
   foreach $ing (@ings)
   {
      $ingSlct .= ' OR ingredient = ' . $FoodDB::dbh->quote($ing); 
   }
   $ingSlct .= ')';

   if (keys %recipes > 0)
   {
      my ($rCode);
      my($stmnt) = 'SELECT ingredient from RECIPE_INGREDIENTS ' .
                   'WHERE recipeCode = ? ' . $ingSlct;
      my($sth) = $FoodDB::dbh->prepare($stmnt) 
                 || die "searchByIngredients() : Could not prepare ($stmnt):" .
                        $FoodDB::dbh->errstr . ")\n";;
      foreach $rCode (keys %recipes)
      {
         $sth->execute($rCode);
         my(@row) = $sth->fetchrow_array();
         $found{$rCode} = $recipes{$rCode} if $#row > -1;
      }
   }
   else
   {
      my($stmnt) = $Recipe::searchSelectStr . $Recipe::searchFromStr .
                   ', RECIPE_INGREDIENTS ' .
                   'WHERE RECIPES.code = RECIPE_INGREDIENTS.recipeCode ';

      $stmnt .= $ingSlct;
      %found = Recipe::getSearchResults($stmnt);
   }
   return %found;
}


sub Recipe::searchByCountry
{
   my($country, $rrecipes) = @_;

   my(%found);
   if ($country ne '')
   {
      my($stmnt) = $Recipe::searchSelectStr . $Recipe::searchFromStr;
      my($recipe_where) = 'WHERE ';
      if (%$rrecipes && keys %$rrecipes > 0)
      {
         $recipe_where .= '(code =';
         $recipe_where .= join(' OR code =', keys %$rrecipes); 
         $recipe_where .= ') AND';
      }
      $recipe_where .= ' country = ' . $FoodDB::dbh->quote($country);

      $stmnt .= $recipe_where;

      %found = Recipe::getSearchResults($stmnt);
   }
   else
   {
      die('Recipe::searchByCountry() : No country name passed');
   }
   return %found;
} # searchByCountry();

sub Recipe::getRecipesByIngredients
{
   my(@ings) = @_;
   searchByIngredients(@ings);
   my(%recipes) = getSearchResults();
   return %recipes;
}


#######################################################
## CATEGORY related functions
#######################################################

sub Recipe::searchByCategories
{
   my($rcats, $rrecipes) = @_;
   my(@cats) = @$rcats;
   die "searchByCategories() : no categories were passed on" if $#cats < 0;
   my(%recipes) = %$rrecipes;

   my($catWhere) = ' AND (categoryCode =' . $cats[0];
   shift @cats;
   my($cat);
   foreach $cat (@cats)
   {
      $catWhere .= ' OR categoryCode = ' . $cat;
   }
   $catWhere .= ')';

   my(%found);
   if (keys %recipes > 0)
   {
      my ($rCode);
      my($stmnt) = 'SELECT categoryCode from RECIPES_CATEGORIES ' .
                   'WHERE recipeCode = ? ' . $catWhere;
      my($sth) = $FoodDB::dbh->prepare($stmnt) 
                 || die "searchByIngredients() : Could not prepare ($stmnt):" .
                        $FoodDB::dbh->errstr . ")\n";;
      foreach $rCode (keys %recipes)
      {
         $sth->execute($rCode);
         my(@row) = $sth->fetchrow_array();
         $found{$rCode} = $recipes{$rCode} if $#row > -1;
      }
   }
   else
   {
      my($stmnt) = $Recipe::searchSelectStr . $Recipe::searchFromStr .
                   ', RECIPES_CATEGORIES WHERE code = recipeCode ' .
                   $catWhere;
      %found = Recipe::getSearchResults($stmnt);
   }
   return %found;
}


## would a prepare speed up things ?
sub Recipe::addCategories
{
   my($rCode, @cats) = @_;
   my($cat, $stmnt);
   foreach $cat (@cats)
   {
      $stmnt = 'INSERT INTO RECIPES_CATEGORIES (recipeCode, categoryCode) ' .
               'VALUES (' . $rCode . ', ' . $cat . ')';
      FoodDB::do($stmnt)
      || die "Could not add category $cat for recipe $rCode : $stmnt (" .
             $FoodDB::dbh->errstr . ")\n";
   }
}

sub Recipe::addIngredient
{
   my($recipeCode, $order, $ing, $qty, $unitCode, $desc, $section) = @_;
   $section = 0 if ($section == undef);

   ## uppercase ings for consistent searches
   $ing =~ tr/[a-z]/[A-Z]/;
   my($stmnt) = 'INSERT INTO RECIPE_INGREDIENTS ' .
                '(recipeCode, ingredient, quantity, unitCode, description,' .
                " section, orderCount) VALUES ($recipeCode, " .
                $FoodDB::dbh->quote($ing) . ", $qty, $unitCode, " .
                $FoodDB::dbh->quote($desc) .  ', ' .
                $section . ', ' . $order . ')';
   FoodDB::do($stmnt)
      || die "Could not add Ingredient : $stmnt (" . $FoodDB::dbh->errstr .
             ")\n";
}

# recipeCode : recipe code of recipe to get ingredients for
#              if not passed then just return a list of all ingredients
#              in the database

sub getIngredients
{
   my($recipeCode) = shift;
   my($stmnt);
   if ($recipeCode)
   {
      $stmnt = 'SELECT * from RECIPE_INGREDIENTS, UNITS where recipeCode = ' .
               $recipeCode . ' AND unitCode = code ORDER BY orderCount';
      my($rIngs);
      my(%ings);
      $rIngs = $FoodDB::dbh->selectall_hashref($stmnt, 'orderCount')
         || die "Could not get ingredients $stmnt (" . $FoodDB::dbh->errstr .
                ")\n";
      %ings = %$rIngs;
      return %ings;
   }
   else
   {
      $stmnt = 'SELECT DISTINCT ingredient from RECIPE_INGREDIENTS ' .
               'ORDER BY INGREDIENT';
      my $sth = $FoodDB::dbh->prepare($stmnt);
      $sth->execute()
         || die "Could not get ingredients recipe : $stmnt (" .
                $FoodDB::dbh->errstr . ")\n";
      my(@ings);
      my(@row);
      while (@row = $sth->fetchrow_array )
      {
         if (!$recipeCode)
         {
            push(@ings, $row[0]);
         }
      }
     return @ings;
      
   }
}

sub Recipe::addUnit
{
   my($u) = @_;
   
   my($stmnt) = 'INSERT INTO UNITS ' .
                '(unit) VALUES (\'' . $u . '\')';
   FoodDB::do($stmnt)
      || die "Could not add recipe : $stmnt ($FoodDB::dbh->errstr)\n";;
   ## now get the code
   my $code = get_last_insert_id();
   return $code;
}

sub Recipe::addSteps
{
   my($rCode, $steps) = @_;
   my($stmnt) = 'UPDATE RECIPES ' .
                'SET steps = ' . $FoodDB::dbh->quote($steps) .
                " WHERE code = $rCode";

   FoodDB::do($stmnt)
      || die "Could not add recipe : $stmnt (" . $FoodDB::dbh->errstr . ")\n";
   
}


sub Recipe::getCategories
{
   my($rRowArry) = DB::Tools::get_all_arrayref($FoodDB::dbh,
                                               'RECIPE_CATEGORY_CODE');
   my(%cats, $rCat);
   foreach $rCat (@$rRowArry)
   {
      $cats{$$rCat[0]} = $$rCat[1];
   }
   return %cats;
}

sub Recipe::getCountries
{
   my($rRowArry) = DB::Tools::get_cols_arrayref($FoodDB::dbh,
                                               'RECIPES', 'country');
   my($rC, @countries);
   foreach $rC (@$rRowArry)
   {
      push(@countries, $$rC[0]) if $$rC[0] && $$rC[0] ne '';
   }
   return \@countries;
}



sub Recipe::addSection
{
   my($rCode, $sec, $secTitle) = @_;
   
   my($stmnt) = 'INSERT INTO ING_SECTIONS ' .
                '(recipeCode, section, sectionTitle) ' .
                'VALUES (' . $rCode . ', ' . $sec . ', ' .
                         $FoodDB::dbh->quote($secTitle) . ')';
   FoodDB::do($stmnt)
      || die "Could not add ingredient section : $stmnt (" .
             $FoodDB::dbh->errstr . ")\n";;
}

sub Recipe::getSections
{
   my($rCode) = shift;
   my($stmnt) = 'SELECT * FROM ING_SECTIONS WHERE recipeCode = ' . $rCode;
   
   my $sth = $FoodDB::dbh->prepare($stmnt);
   $sth->execute()
      || die "Could not get ingredients sections : $stmnt (" .
             $FoodDB::dbh->errstr . ")\n";
   my (@row);
   my(@secs);
   $secs[0] = '';
   while (@row = $sth->fetchrow_array )
   {
      $secs[$row[1]] = $row[2];
   }
   return @secs;
}

## this function allows complex searches for recipes
## it is used in conjunction with other searchBy* functions
sub Recipe::getSearchResults
{
   my($searchStmnt) = shift;

#print "$searchStmnt<BR>";

   my $sth = $FoodDB::dbh->prepare($searchStmnt);
   $sth->execute()
      || die "Could not get Recipes : $searchStmnt (" .
             $FoodDB::dbh->errstr . ")\n";
   my (@row);
   my(%recipes);
   while (@row = $sth->fetchrow_array)
   {
      $recipes{$row[0]} = $row[1];
   }
   return %recipes;
}

BEGIN
{
   ## Global variable used to complex search for recipes
   $Recipe::searchSelectStr = 'SELECT code, name ';
   $Recipe::searchFromStr = 'FROM RECIPES ';
}
1;
