package CGI::Product;

use CGI::SmartForm;
use CGI::Tools;

## CGI Product related functions


sub get_stores
{
   return if %CGI::Product::stores;

   require DB::Store;
   DB::Store::make($CGI::Product::dbh);

   my $rStores = DB::Store::get();
   my $k;
   ## empty
   push(@CGI::Product::store_codes, 0);
   $CGI::Product::stores{0} = '';
   
   foreach $k (keys %$rStores)
   {
      push(@CGI::Product::store_codes, $k);
      $CGI::Product::stores{$k} = ${$$rStores{$k}}{'name'} . '-' .
                       ${$$rStores{$k}}{'city'};
   }
}


## gets HTML for a single product
## calls table_field to format
## hdr : if a header is needed for the table
## row : if 1 then list one row per product
sub prodHTML
{
   my($rproduct, $rprice, $edit, $row, $hdr) = @_;
   if ($hdr)
   {
      my($title) ;
      $title = '<TH>UPC/Product ID</TH><TH>Name</TH><TH>Make</TH>' .
               '<TH>Description</TH><TH>Quantity</TH>' .
               '<TH>Price($)</TH>' if $hdr;
      $title .= '<TH>Price/Unit($)</TH>' if !$edit;
      $title .= '<TH>Store</TH>';
      return $title;
   }
   my %product = %$rproduct;
   my $html;
   $html .= $row ? '' : '<TABLE>' . "\n";


   $html .= CGI::Tools::table_field($row,
            cgi_object()->textfield($edit, -name=>'UPC', -override=>1,
                                           -default=>$product{'UPC'},
                                           -size=>12, -maxlength=>12),
            'UPC/Product ID :');

   $html .= CGI::Tools::table_field($row,
            cgi_object()->textfield($edit, -name=>'name', -override=>1,
                                           -default=>$product{'name'},
                                           -size=>30, -maxlength=>80),
            'Name :');

   $html .= CGI::Tools::table_field($row,
            cgi_object()->textfield($edit, -name=>'make', -override=>1,
                                           -default=>$product{'make'},
                                           -size=>30, -maxlength=>80),
            'Make :');

   $html .= CGI::Tools::table_field($row,
            cgi_object()->textfield($edit, -name=>'description', -override=>1,
                                           -default=>$product{'description'},
                                           -size=>50, -maxlength=>120),
            'Description :');

   my $uHTML = cgi_object()->textfield($edit, -name=>'unit', -override=>1,
                                              -default=>$product{'unit'},
                                              -size=>4, -maxlength=>20);

   $html .= CGI::Tools::table_field($row,
            cgi_object()->textfield($edit, -name=>'quantity', -override=>1,
                                           -default=>$product{'quantity'},
                                           -size=>4, -maxlength=>10) .
                                           ' ' . $uHTML, 'Quantity :');

   ## Price info
   get_stores();
   $html .= CGI::Tools::table_field($row,
            cgi_object()->textfield($edit, -name=>'price', -override=>1,
                                           -default=>$$rprice{'price'},
                                           -size=>8, -maxlength=>12),
            'Price : $');

   $html .= CGI::Tools::table_field($row,
            cgi_object()->textfield($edit, -name=>'increment', -override=>1,
                                           -default=>$product{'increment'},
                                           -size=>4, -maxlength=>20),
            'Increment :') if $edit;

   ## calculated info
   ## price per unit
   my $ppu = '';
   if ($$rprice{'price'} && $product{'quantity'} && $product{'quantity'} != 0)
   {
      $ppu = $$rprice{'price'} / $product{'quantity'};
      $ppu *= $product{'increment'}
          if $product{'increment'} && $product{'increment'} > 0;
      $ppu = sprintf '%.2f', $ppu;
      $ppu .= '/' if $product{'unit'};
      $ppu .= $product{'increment'}
         if $product{'increment'} && $product{'increment'} > 0;
      $ppu .= $product{'unit'} if $product{'unit'};
   }
   $html .= CGI::Tools::table_field($row,
                       $ppu, 'Price/Unit($) : ') if !$edit;

   $html .= CGI::Tools::table_field($row,
            cgi_object()->scrolling_list($edit,
                                         -name=>'storeCode',
                                         -labels=>\%CGI::Product::stores,
                                         -values=>\@CGI::Product::store_codes,
                                         -size=>1,
                                         -override=>1,
                                         -default=>$$rprice{'storeCode'},),
            'Store :');

   $html .= $row ? '' : '</TABLE>' . "\n";

   $html .= '<INPUT TYPE=submit NAME=action VALUE=Add>'
      if cgi_object()->param('request') eq 'Add';
   $html .= '<INPUT TYPE=submit NAME=action VALUE=Update>'
      if cgi_object()->param('request') eq 'Edit';
   ## hide product UPC/ID being edited so it can be updated
   $html .= '<INPUT TYPE=hidden NAME=edit_UPC VALUE=' . $product{'UPC'} .
                '>'
      if cgi_object()->param('request') eq 'Edit';
   $html .= '<INPUT TYPE=submit NAME=action VALUE=Search>'
      if cgi_object()->param('request') eq 'Search';

   return $html;
} # prodHTML()

## set DB to work with
sub setDB
{
   my($dbh) = shift;
   $CGI::Product::dbh = $dbh;

   require DB::Product;
   DB::Product::make($dbh);
   require DB::Price;
   DB::Price::make($dbh);
}

## sets/gets the cgi object to work with ()
sub cgi_object
{
   if ($_[0])
   {
      $CGI::Product::q = shift;
      bless $CGI::Product::q, 'CGI::SmartForm';
   }
#print "OBJ 1 " . $CGI::Product::q . '<BR>';
   $CGI::Product::q = $CGI::Q if ! $CGI::Product::q && $CGI::Q; # default object
#print "OBJ 2 " . $CGI::Product::q . '<BR>';
   $CGI::Product::q = new CGI() if ! $CGI::Product::q;
#print "OBJ 3 " . $CGI::Product::q . '<BR>';
   return $CGI::Product::q;
}

BEGIN
{
}

1;
