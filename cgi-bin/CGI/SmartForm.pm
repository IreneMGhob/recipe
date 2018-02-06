package CGI::SmartForm;

# See the bottom of this file for the POD documentation.  Search for the
# string '=head'.

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).


use CGI;
use CGI::Util 'rearrange';

@ISA = ('CGI');

$CGI::DefaultClass = 'CGI::SmartForm';
$CGI::SmartForm::AutoloadClass = 'CGI';



sub textfield
{
   my($self, $edit, @parms) = CGI::self_or_default(@_);
   if ($edit)
   {
      return $self->SUPER::textfield(@parms);
   }
   else
   {
      my($val) = CGI::Util::rearrange([DEFAULT], @parms);
      return $val;
   }
}



sub scrolling_list
{
   my($self, $edit, @parms) = CGI::self_or_default(@_);
   if ($edit)
   {
      return $self->SUPER::scrolling_list(@parms);
   }
   else
   {
      my($val, $rLabels) = CGI::Util::rearrange([DEFAULT,LABELS], @parms);
      return $$rLabels{$val};
   }
}
1;



=head1 NAME

CGI::SmartForm - Subclass of CGI overriding form method calls to enable
                 editable and non-editable form HTML creation.

=head1 SYNOPSIS

    use CGI::SmartForm;

    textfield($edit, @parms);

    scrolling_list($edit, @parms);


=head1 DESCRIPTION

CGI::Push is a subclass of the CGI object.  It allows single calls for
fields regardless of whether in editable or non-editable form, simplifying
CGI scripts.  All calls are the same as the CGI calls, except that the
first parameter 'edit' is passed to indicate weather this is an editable
form or not.

=head1 USING CGI::SmartForm

As for CGI you may call CGI::SmartForm subroutines in the object oriented manner
or not, as you prefer:

    use CGI::SmartForm;
    $q = new CGI::SmartForm;
    $q->textfield($edit, ...);

        -or-

    use CGI::SmartForm;
    textfield($edit, ...);

=cut
