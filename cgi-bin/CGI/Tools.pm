package CGI::Tools;

=head1 CGI::Tools

Tools to use in CGI scripts.

=cut
use CGI;
#
#
#
#=item save_hash($id, $rhash)
#Saves a hash
#=cut
#sub save_hash_html
#{
#   my($id, $rhash) = @_;
#   my($key, $html, @keys);
#print "UPC ", $$rhash{'UPC'} , "<BR>";
#   foreach $key (keys %$rhash)
#   {
#print "KEY $key<BR>";
#      $html .= '<INPUT TYPE=hidden NAME=' . $id . '%' . $key . ' VALUE="' .
#               $$rhash{$key} . '">' . "\n";
#      push(@keys, $key);
#   }
#   $html .= '<INPUT TYPE=hidden NAME=keys%' . $id . ' VALUE="' .
#            join(',', @keys) . '">' . "\n";
#   return $html;
#}
#
#sub save_hash
#{
#   print save_hash_html(@_);
#}
#
#=item get_hash
#Gets a hash saved by save_hash()
#=cut
#sub get_hash
#{
#   my($q, $id) = @_;
#   my($hash);
#   my($keys) = $q->param('keys%' . $id); 
#   my $key;
#   foreach $key (split(',', $keys))
#   {
#      $hash{$key} = $q->param($id . '%' . $key);
#   }
#}
#
#
### creates an array from CGI params
#sub array_param
#{
#   my($q, @params) = @_;
#   my $p;
#   my @arry;
#   foreach $p (@params)
#   {
#      push(@arry, $q->param($p));
#   }
#   return \@arry;
#}

=head2 tf(form, nm, val, sz, ml)

Calls textfield() if in a form, otherwise displays the value.
Useful to display a field in both editable and non-editable contexts.

=head3 Parameters:

=item form : if 0, then this is not a form and hence display value, otherwise
display input field.

=item nm: name of text field, used only if in form

=item val: value of field

=item sz: size of text field, used only if in form

=item ml: maximum length of text field, used only if in form

=cut

sub tf
{
   my($form, $nm, $val, $sz, $ml) = @_;
   if ($CGI::Tools::q)
   {
      return $CGI::Tools::q->textfield(-name=>$nm,
                              -default=>$val, # defaults to param($nm)
                              -override=>1,
                              -size=>$sz,
                              -maxlength=>$ml) if $form;
   }
   else
   {
      return CGI::textfield(-name=>$nm,
                            -default=>$val, # defaults to param($nm)
                            -override=>1,
                            -size=>$sz,
                            -maxlength=>$ml) if $form;
   }
   return $val if !$form;
}



=head2 sl(form, nm, sz, rvals, rlabels)

Call scrolling_list() if in a form, else displays the selected value in param().
Useful to display a field in both editable and non-editable contexts.

=head3 Parameters :

=item form : if 0, then this is not a form and hence display value, otherwise
display input field.

=item nm: name of scrolling list, used only if in form

=item sz: size of scrolling list, used only if in form

=item rvals : reference to array passed to scrolling_list() as values

=item rlabels : reference to hash passed to scrolling_list() as labels

=cut

sub sl
{
   my($form, $nm, $sz, $val, $rvals, $rlabels) = @_;

   if (!$form)
   {
      return $$rlabels{$val};
   }
   else
   {
      return $main::q->scrolling_list(-name=>$nm, -values=>$rvals ,
                                      -size=>$sz,
                                      -default=>$val,
                                      -labels=>$rlabels);
   }
}


=head2 table_field(row, val, title)

Displays content either in a cell in a row in a table or in a whole row in table
with title and value.
Returns an HTML string.

=head3 Parameters :

=item row : if row = 1 then put val in a cell, else put val and title in
a separate row.

=item val : value of field

=item title : title of field. If row != 1, then title needs to be in first cell
or row.

=cut

sub table_field
{
   my($row, $val, $title) = @_;
   if ($row && $row == 1)
   {
      return '<TD>' . $val . '</TD>';
   }
   else
   {
      return '<TR><TD ALIGN=right><EM>' . $title .
             ' </EM></TD><TD>' . $val . '</TD></TR>' . "\n";
   }
}


=head2 hash_param(params)

Creates a hash from CGI params.  Returns a reference to the hash.

=head3 Parameters :

=item params : array of keys of hash, which are used as parameters to param().

=cut

sub hash_param
{
   my(@params) = @_;
   my $p;
   my %hash;
   foreach $p (@params)
   {
      $hash{$p} = $CGI::Tools::q ? $CGI::Tools::q->param($p) : CGI::param($p);
   }
   return \%hash;
}


=head2 param_hash(hashref)

Returns HTML that will make hidden variables for each entry in hash. Opposite
of hash_param().

=head3 Parameters :

=item hashref : reference to hash to hide

=cut

sub param_hash
{
   my($hashref) = shift;
   my $k;
   my $html = "\n";
   foreach $k (keys %$hashref)
   {
      $html .= '<INPUT TYPE=hidden NAME=' . $k . ' VALUE="' .
               $$hashref{$k} . '">';
   }
   return $html;
}


=head2 cgi_object(q)

Sets the CGI object to work with.  If this function is not called, then
default CGI object is used.

=head3 Parameters :

=item q : cgi object to work with.


=cut

sub cgi_object
{
   $CGI::Tools::q = shift;
}

1;
