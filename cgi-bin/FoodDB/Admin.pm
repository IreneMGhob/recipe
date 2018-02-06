package FoodDB::Admin;

use DBI;

$recipesCreate = <<'SQL_RECIPES';
CREATE TABLE IF NOT EXISTS RECIPES (
   code INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
   name VARCHAR(80) NOT NULL,
   description VARCHAR(240),
   steps TEXT,
   calories SMALLINT UNSIGNED,		-- per yield
   cholestrol SMALLINT UNSIGNED,	-- mg
   sodium SMALLINT UNSIGNED,		-- mg
   carb SMALLINT UNSIGNED,		-- g
   fiber SMALLINT UNSIGNED,		-- g
   protein SMALLINT UNSIGNED,		-- g
   fat SMALLINT UNSIGNED,		-- g
   saturatedFat TINYINT UNSIGNED,	-- g
   prepTime SMALLINT UNSIGNED,		-- minutes
   cookingTime SMALLINT UNSIGNED,	-- minutes
   yield TINYINT UNSIGNED,
   yieldUnit VARCHAR(15),
   country VARCHAR(40),			-- which country if any
   source VARCHAR(80),			-- where did we get this recipe from
   creator VARCHAR(100),		-- who created it
   create_dt DATETIME,			-- when was it created
   update_dt DATETIME			-- when was it updated last
);
SQL_RECIPES


$recipeCategoryCreate = <<SQL_CATEGORY;
DROP TABLE RECIPE_CATEGORY_CODE;
CREATE TABLE RECIPE_CATEGORY_CODE (
   code SMALLINT NOT NULL,
   category VARCHAR(40) NOT NULL
);
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (1, 'Salad');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (2, 'Appetizer');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (3, 'Bread');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (4, 'Cake');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (5, 'Dessert');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (6, 'Fish & Seafood');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (7, 'Breakfast & Brunch');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (8, 'Soup');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (9, 'Pie');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (10, 'Beef');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (11, 'Poultry');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (12, 'Pork');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (13, 'Vegetables');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (14, 'Cookies');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (15, 'Sauce');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (16, 'Dip');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (17, 'Pasta');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (18, 'Kids');
INSERT INTO RECIPE_CATEGORY_CODE (code, category) VALUES (19, 'Drinks');

CREATE TABLE IF NOT EXISTS RECIPES_CATEGORIES (
   recipeCode INT,
   categoryCode SMALLINT
);

SQL_CATEGORY

$recipeIngredientCreate = <<'SQL_RECIPE_INGREDIENTS';
CREATE TABLE IF NOT EXISTS RECIPE_INGREDIENTS (
   recipeCode INT NOT NULL,
   ingredient VARCHAR(40) NOT NULL,
   quantity VARCHAR(20),
   unitCode INT,
   description VARCHAR(80),
   section TINYINT NOT NULL,
   orderCount TINYINT NOT NULL  -- order of ingredient in recipe
);
SQL_RECIPE_INGREDIENTS

$recipeIngSectionsCreate = <<'SQL_REC_ING_SECTIONS';
CREATE TABLE IF NOT EXISTS ING_SECTIONS (
   recipeCode INT NOT NULL,
   section TINYINT NOT NULL,
   sectionTitle VARCHAR(80)
);
SQL_REC_ING_SECTIONS

## runs sql statements
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

sub make
{
   my($dbh) = shift;
   sdo($dbh, $recipesCreate);
   sdo($dbh, $recipeIngredientCreate);
   sdo($dbh, $recipeCategoryCreate);
   sdo($dbh, $recipeIngSectionsCreate);
   require DB::Unit;
   DB::Unit::make($dbh);
}

1;
