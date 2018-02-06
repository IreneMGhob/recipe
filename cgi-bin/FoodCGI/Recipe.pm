package FoodCGI::Recipe;

use CGI;
use FoodDB::Recipe;

# transfers an array to a comma delimeted string (with an 'and' before last
# element)
sub arrayToCst
{
   my($andOr, @a) = @_;
   my($s) = $a[0];
   shift @a;
   my($e, $i);
   foreach $e (@a)
   {
      $i++;
      $s .= ', ' . $e if $i <= $#a;
      $s .= ' ' . $andOr . ' ' . $e if $i > $#a;
   }
   return $s;
}

# return HTML for selecting Categories
sub recipeCategorySelectHTML
{
   my($cols) = shift;
   $cols = 3 if (!$cols) ;
   my(%cats) = Recipe::getCategories();
   my($cat, $i, $html);
  
   $html .= '<TABLE><TR>';
   foreach $cat (keys %cats)
   {
      $i++;
      $html .= '<TD><INPUT TYPE="checkbox" NAME=cat' .
               $cat . ' VALUE="' . $cats{$cat} . '">' .
               $cats{$cat} . '</TD>' . "\n";
      $html .= '</TR><TR>' if $i % $cols == 0;
   }
   $html .= '</TR></TABLE>';
   $html .= '<INPUT NAME="categoryCount" TYPE="hidden" VALUE=' . $i . '>';

   return $html;
}

sub countrySelectHTML
{
   my $slctCountry = shift; # default selection, if any

   my $rcountries = Recipe::getCountries();
   my($c, $html);
   $html = '<SELECT NAME="country">';
   $html .= '<OPTION>' . '';
   foreach $c (@$rcountries)
   {
      $html .= '<OPTION>' . $c;
   }
   $html .= '</SELECT>';
   return $html;
} # countrySelectHTML()

sub ingredientSelectHTML
{
   my @slctIngs = @_;

   my @ings = FoodDB::Recipe::getIngredients();
   return '' if $#ings == -1;
   my $slctHTML = '<SELECT NAME="ings" MULTIPLE SIZE=14>' . "\n";
   foreach $ing (@ings)
   {
      $slctHTML .= '<OPTION';
      $slctHTML .= ' SELECTED' if grep /^$ing$/, @slctIngs;
      $slctHTML .= '>' . $ing . "\n";
   }
   $slctHTML .= '</SELECT>' . "\n";
   
   $slctHTML .= '<P CLASS=small_P>To select more than one<BR>' .
                'ingredient, press the \'Ctrl\' button <BR>' .
                'while selecting with your mouse.</P>' if $#ings > 0;

   return $slctHTML;
}


sub getCategories
{
   my($q) = shift;
   my(@cats, @catsStrs);
   my($i) = 1;
   my($catNum) = $q->param('categoryCount');
   while ($i <= $catNum)
   {
      if ($q->param('cat' . $i) ne '')
      {
         push(@catsStrs, $q->param('cat' . $i));
         push(@cats, $i);
      }
      $i++;
   }
   return(\@cats, \@catsStrs);
}



sub addRecipe
{
   my($q) = shift;
   my ($html);
   ## put all steps in one string
   $i = 1;
   while ($q->param('step' . $i))
   {
      $steps .= $q->param('step' . $i++) . "\n";
   }
   
   use CGI::Login;
   my $id = CGI::Login::getLoginId($q);
   my($code) = Recipe::add($q->param('name'), $q->param('desc'),
                           $steps, $q->param('calories'),
                           $q->param('cholestrol'),
                           $q->param('sodium'), $q->param('carb'),
                           $q->param('fiber'), $q->param('protein'),
                           $q->param('fat'), $q->param('saturatedFat'),
                           $q->param('prepTime'), $q->param('cookingTime'),
                           $q->param('yield'), $q->param('yieldUnit'),
                           $q->param('country'), '', $id);

   my($rCats, $rCatsStrs) = getCategories($q);
   my(@cats) = @$rCats;
   Recipe::addCategories($code, @cats) if $#cats > -1;

   my($i)=0;
   my($ing, $qty, $unitCode, $desc);
   my(@sections, $sec, $secCount);
   while ($q->param('ing' . $i))
   {
      $ing = $q->param('ing' . $i);
      $qty = $q->param('qty' . $i);
      $unitCode = $q->param('unit' . $i);
      $desc = $q->param('ing_desc' . $i);
      if ($q->param('sec' . $i) ne '' && $q->param('sec' . $i) ne $sec)
      {
         ## if new section do this :
         $sec = $q->param('sec' . $i);
         $secCount++;
         Recipe::addSection($code, $secCount, $sec);
      }
      ## if does not belong to a section then should belong to default section 0
      $thisSecCount = $secCount;
      $thisSecCount = 0 if $q->param('sec' . $i) eq '';
      Recipe::addIngredient($code, $i, $ing, $qty, $unitCode, $desc,
                            $thisSecCount);
      $i++;
   }
   $html .= 'Added Recipe<BR>';

   if ($q->param('picture'))
   {
      # get rid of path
      my $file = $q->param('picture');
      ## get extension
      $_ = $file;
      my $ext = $1 if ( /\.(.*)/g );
      $ext =~ tr/[A-Z]/[a-z]/;
      if ($ext ne 'jpg' && $ext ne 'gif')
      {
         $html .= "Your picture could not be added.  It needs to be a '.gif' of '.jpg'.";
         return $html;
      }
      my $pwd = `pwd`;
      chop $pwd;
      $local_file = $pwd . '/pics/' . $code . '.' . $ext;
      open(OH, "> $local_file") || die ('cant open ' . $local_file);;
      my $length;
      while (<$file>)
      {
         $length += length($_);
         print OH $_;
      }
      close OH;
      close PH;
      if ($length >= 150000)
      {
         $html .= 'Your Recipe picture is too big, please send it as an ' .
               'attachment to <A HREF="mailto:irenemg@elinkwebdesign.com?' .
               'subject=Picture for Recipe ' . $code . '">' .
               'irenemg@elinkwebdesign.com</A> and we will resize it and ' .
               'post it for you. Thank you for your co-operation.';
         unlink($local_file);
      }

   }
   return $html;
} # addRecipe()

# checks if all elements in array1 are in array2
sub inArray
{
   my($rA1, $rA2) = @_;
   my(@a1) = @$rA1;
   my(@a2) = @$rA2;
   my($e);
   foreach $e (@a1)
   {
      my(@es) = grep /$e/, @a2;
      return 0 if $#es < 0;
   }
   return 1;
}

sub getRecipes
{
   my($q) = shift;
   my(@ings) = $q->param('ings');
   my($rCats, $rCatsStrs) = getCategories($q);
   my(@cats) = @$rCats; 
   my($name) = $q->param('recipeName');
   my($country) = $q->param('country');
   my(%recipes);
   %recipes = Recipe::searchByName($name)
              if $name ne '';
   
   %recipes = Recipe::searchByIngredients(\@ings, \%recipes)
              if ($#ings > -1);
   %recipes = Recipe::searchByCategories(\@cats, \%recipes)
              if ($#cats > -1);
   %recipes = Recipe::searchByCountry($country, \%recipes)
              if ($country && $country ne '');
   # check that these recipes have ALL the ingredients, if ALL is selected
   # and more than one ingredient selected
   if ($q->param('select') eq 'all' && $#ings > 0)
   {
      my(%allIngRecipes);
      my($rCode, %rIngs, $i);
      foreach $rCode (keys %recipes)
      {
         my(@rIngs);
         %rIngs = FoodDB::Recipe::getIngredients($rCode);
         ## get an array of ingredients from %ings
         foreach $i (keys %rIngs)
         {
            push(@rIngs, $rIngs{$i}{'ingredient'});
         }
         $allIngRecipes{$rCode} = $recipes{$rCode} if inArray(\@ings, \@rIngs);
      }
      %recipes = %allIngRecipes;
   }

   my($html);

   ## display search criteria
   if ($name ne '')
   {
      $html .= '<H2>Recipes with Names matching \'' . $name . '\'</H2>';
   }
   if ($#ings > -1)
   {
      $html .= '<H2>Ingredients : ';
      my($andOr) = 'and';
      $andOr = 'or' if $q->param('select') eq 'any';
      $html .= arrayToCst($andOr, @ings);
      $html .= "</H2>\n";
   }
   if ($#cats > -1)
   {
      $html .= '<H2>Categories : ';
      $html .= arrayToCst('and', @$rCatsStrs);
      $html .= "</H2>\n";
   }
   if ($country && $country ne '')
   {
      $html .= '<H2>Country : ' . $country . '</H2>';
   }

   if (keys %recipes == 0 && %allIngRecipes == 0)
   {
      $html .= 'No recipes found for your search criteria.';
   }
   else
   {

      $html .= '<H3>The following recipes were found for ' .
               'the search criteria above.</H3>' if $html ne '';
      my($rCode);
      foreach $rCode (keys %recipes)
      {
         $html .= '<A HREF=/cgi-bin/tools/content.cgi?content=recipe.html' .
                  '&code=' . $rCode . '>' . $recipes{$rCode} . '</A><BR>';
      }
   }
   return $html;
}

sub getARecipe
{
   my($q) = shift;
   my(%recipe) = FoodDB::Recipe::get($q->param('code'));
   $html = '<TR><TD COLSPAN=2><H1>' . $recipe{'name'} . '</H1></TD></TR>';
   $html .= '<TR><TD ROWSPAN=3>';
   $html .= $recipe{'description'} . '<BR>' if $recipe{'description'};
   $html .= 'This recipe is from ' . $recipe{'country'} . '.<BR>' if $recipe{'country'};
   $html .= '<H2>Ingredients</H2>';
   my(%ings) = FoodDB::Recipe::getIngredients($q->param('code'));
   my(@secs) = Recipe::getSections($q->param('code'));
   my($currSec);
   sub numerically { $a <=> $b }
   foreach $i (sort numerically keys %ings)
   {
      ## if section 0 and is not the first ingredient and previous ingredient
      ## was in a section then separate by a line
      if ($ings{$i}{'section'} == 0 && $i != 0 && $currSec != 0)
      {
         $html .= '<BR>';
      }
      elsif ($ings{$i}{'section'} != 0 && $currSec ne $ings{$i}{'section'})
      {
         $html .= '<H3>' . $secs[$ings{$i}{'section'}] . '</H3>';
      }
      $currSec = $ings{$i}{'section'};
      $html .= $ings{$i}{'quantity'} . ' ' . $ings{$i}{'unit'} .
               ' ' . $ings{$i}{'ingredient'};
      $html .= ', ' . $ings{$i}{'description'} if $ings{$i}{'description'};
      $html .= '<BR>' . "\n";
   }
   my(@steps) = split(/\n/, $recipe{'steps'});
   $html .= '<H2>Steps</H2>';
   my($s);
   $html .= '<OL>' . "\n";
   foreach $s (@steps)
   {
      $html .= '<LI>' . $s . "\n";
   }
   $html .= '</OL>' . "\n";
   $html .= '</TD>';

   ## SECOND COLUMN
   my($cwidth) = 120;
   ## check if there is a picture
   my $gif = 'pics/' . $q->param('code') . '.gif';
   my $jpg = 'pics/' . $q->param('code') . '.jpg';
   my $picHTML;
   my $pic = $gif if -f $gif;
   $pic = $jpg if -f $jpg;
   $picHTML .= '<A HREF="/cgi-bin/tools/content.cgi?content=picture.html' .
               '&recipe_name=' . $recipe{'name'} . '&picture=/' . $pic .
               '"><IMG SRC=/' . $pic . ' WIDTH=' . $cwidth . ' BORDER=0></A>'
      if $pic ne '';

   ## nutrition information
   my($nutHTML) = '';
   $nutHTML .= 'Calories : ' . $recipe{'calories'} . '<BR>'
      if $recipe{'calories'};
   $nutHTML .= 'Cholestrol : ' . $recipe{'cholestrol'} . 'mg<BR>'
      if $recipe{'cholestrol'} ne '';
   $nutHTML .= 'Fat : ' . $recipe{'fat'} . 'g<BR>' if $recipe{'fat'} ne '';
   $nutHTML .= 'Saturated Fat : ' . $recipe{'saturatedFat'} . 'g<BR>'
      if $recipe{'saturatedFat'} ne '';
   $nutHTML .= 'Sodium : ' . $recipe{'sodium'} . 'mg<BR>'
      if $recipe{'sodium'} ne '' ;
   $nutHTML .= 'Carbohydrate : ' . $recipe{'carb'} . 'g<BR>'
      if $recipe{'carb'} ne '';
   $nutHTML .= 'Fiber : ' . $recipe{'fiber'} . 'g<BR>'
      if $recipe{'fiber'} ne '';
   $nutHTML .= 'Protein : ' . $recipe{'protein'} . 'g'
      if $recipe{'protein'} ne '';
   $nutHTML = '<H2>Nutrition</H2>' . $nutHTML if $nutHTML ne '';

   if ($picHTML)
   {
      $html .= '<TD CLASS=hl1 VALIGN=top>' . "\n" . $picHTML;
      $html .= "\n" . '</TD></TR><TR>';
   }
   if ($nutHTML ne '')
   {
      $html .= '<TD CLASS=hl1 VALIGN=top WIDTH=' . $cwidth . '>' . "\n" . $nutHTML;
      $html .= "\n" . '</TD></TR><TR>';
   }

   my $timeHTML;
   $timeHTML = 'Preparation time : ' . $recipe{'prepTime'} . '<BR>' if ($recipe{'prepTime'} != 0);
   $timeHTML .= 'Cooking time : ' . $recipe{'cookingTime'} . '<BR>' if ($recipe{'cookingTime'} != 0);

   if ($timeHTML ne '')
   {
      $html .= '<TD CLASS=hl1 VALIGN=top WIDTH=' . $cwidth . '>' . "\n" . $timeHTML;
      $html .= "\n" . '</TD>';
   }
   $html .= '</TR>', "\n";

   return $html;
   
}

sub handleRecipeRequest
{
   my($q, $rqst) = @_;
   my($html);
   if (!$rqst)
   {
      $html = addRecipe($q) if ($q->param('add_recipe'));
      $html = getRecipes($q) if ($q->param('get_recipes'));
   }
   else
   {
      $html = getARecipe($q) if ($rqst eq 'recipe');
   }
   return $html;
}

1;
