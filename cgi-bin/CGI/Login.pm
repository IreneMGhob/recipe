package CGI::Login;
# package managing user login for CGI programs
# used with a login.html

use CGI::Cookie;
use DB::Login;
use DB::User;

$CGI::Login::cgi = '/cgi-bin/tools/content.cgi?content=login.html';

$CGI::Login::forgotPasswd = 'Oops ! I forgot my password';
$CGI::Login::loginIDCookieName = 'LoginId';
$CGI::Login::registerHTML = '<P>If you do not have a Login id, please <A HREF=' . $CGI::Login::cgi . 
                      '&register=now>Register</A> now.</P>';
$CGI::Login::passwordHTML = '<P>If you forgot your password, <A HREF=' . $CGI::Login::cgi .
                      '&forgot_password=yes>click here</A>.</P>';

sub logon
{
   my($q) = @_;

   my($html);
   my($loginStatus) =
      DB::Login::logon($q->param('id'), $q->param('passwd'));
   if ($loginStatus >= 0)
   {
      use CGI::Cookie;
      print $q->header(-COOKIE => new CGI::Cookie (
                       -NAME    => $CGI::Login::loginIDCookieName,
                       -VALUE   => $q->param('id')
                       ));
      $CGI::Login::LoginId = $q->param('id');
      print '<HEAD><META HTTP-EQUIV="Refresh" CONTENT="0;URL=/cgi-bin/tools/content.cgi?content=welcome.html"></HEAD>';
   }

   return $loginStatus;
}

sub logoff
{
   my($q) = shift;
   print $q->header(-COOKIE => new CGI::Cookie (
                       -NAME    => $CGI::Login::loginIDCookieName,
                       -EXPIRES => '0s'
                    ));
}



sub getLoginId
{
   my($q) = shift;
   my $login = $q->cookie($CGI::Login::loginIDCookieName);
   return $login;
}



## Ret : 2 if logged on, with temp password
## Ret : 1 if logged on
##       0 if logged off
sub verify
{
   my($q) = shift;
   my $login = getLoginId($q);
   if ($login && $login ne '')
   {
      ## do the temp password check only if we have a database handle
      return 2 if $DB::Login::dbh && DB::Login::temp_password($login);
      return 1;
   }
   else
   {
      return 0;
   }
}

sub register
{
   my($q) = shift;
   my $html = '<H1>Register</H1>';
   ## check that we have all fields

   my $rc = DB::User::add($q->param('email'),
                          $q->param('fname'),
                          $q->param('lname'),
                          $q->param('email') );
   if ($rc != 0)
   {
      $html .= '<H2>Error : Login ID \'' . $q->param('email') .
                  '\' is already in use.  ' . 
                  'Please go back and choose a different ID.</H2>';
   }
   else
   {
      $html .= '<H2>Thank you for registering ' . $q->param('email') . '.</H2>';
      $html .= '<P>You will shortly receive an email with a temporary password.<BR>' . 
               'Please keep your password in a safe easy to remember spot.' .
               '</P>';

      my $temp_passwd = rand;
      $temp_passwd = substr($temp_passwd, 2, 9);

      if (DB::Login::add($q->param('email'), $temp_passwd) == 0)
      {

         ## send mail with temp password
         require Mail::Mailer;
         my $type = 'sendmail';
         my $mailprog = Mail::Mailer->new($type);
         my %headers = (
                           'To' => $q->param('email'),
                           'From' => 'info@elinkwebdesign.com',
                           'Subject' => 'Tried Tested & True Registration'
                          );
         $mailprog->open(\%headers);
         print $mailprog
                  "Thank you for registering.\n\n" .
                  "This email is to confirm your registeration.\n" .
                  'Your login ID is ' . $q->param('email') .
                  " and your temporary password is $temp_passwd.\n\n" .
               'If you would like to change your password, go to <A HREF=' .
               $CGI::Login::cgi . '&change_password=now>click here</A>' .
                  'If you have any questions or concerns, please send ' .
                  'us an email at info@elinkwebdesign.com.'; 
         $mailprog->close;
      }
   }
   return $html;
} # register()


sub register_form
{
   my($q) = shift;
   $html = <<HTML;
<H1>Register</H1>
<SCRIPT>
function valid()
{
  f = document.register;
  ok = false;
  if (!f.fname.value || !f.lname.value || !f.email.value)
     alert('Please fill in all fields.');
  else
     ok = true;
  return ok;
}
</SCRIPT>
<H2>Please fill in all of the following :</H2>
<FORM NAME="register" onSubmit="return valid()">
<TABLE BORDER=1>
<TR><TD>
<TABLE CLALLPADDING=3 border=0>
<TR><TD>First Name : </TD><TD><INPUT NAME="fname" TYPE="text"></TD></TR>
<TR><TD>Last Name : </TD><TD><INPUT NAME="lname" TYPE="text" SIZE=25></TD></TR>
<TR><TD>Email Address : </TD><TD><INPUT NAME="email" TYPE="text" SIZE=30></TD>
</TR>
</TABLE>
</TD></TR>
</TABLE>
<INPUT TYPE="submit" NAME="action" VALUE="Register">
<INPUT TYPE="hidden" NAME="content" VALUE="login.html">
</FORM>
HTML
} # register_form()


sub change_password_form
{
   my($q) = shift;
   my $html = <<HTML;
<H1>Change Your Password</H1>
<SCRIPT>
function valid()
{
   f =  document.password;
   ok = false;
   if (!f.temp.value || !f.newp.value || !f.confirm.value)
      alert('Please enter all passwords.');
   else if (f.newp.value != f.confirm.value)
      alert('Your new password is not the same as the confirm password. Please re-enter.');
   else
      ok = true;
   return ok;
}
</SCRIPT>
<H2>Please fill in all of the following :</H2>
<FORM NAME="password" onSubmit="return valid()" METHOD="post">
<TABLE BORDER=1>
<TR><TD>
<TABLE CLALLPADDING=3 border=0>
<TR><TD>Temporary Password : </TD><TD><INPUT NAME="temp" TYPE="password"></TD></TR>
<TR><TD>New Password : </TD><TD><INPUT NAME="newp" TYPE="password"></TD></TR>
<TR><TD>Confrim New Password : </TD><TD><INPUT NAME="confirm" TYPE="password"></TD>
</TR>
</TABLE>
</TD></TR>
</TABLE>
<INPUT TYPE="submit" NAME="action" VALUE="Change Password">
<INPUT TYPE="hidden" NAME="content" VALUE="login.html">
</FORM>
HTML
   return $html;
}


sub change_password
{
   my($q) = shift;
   my $id = CGI::Login::getLoginId($q);
   ## now check that the old password is right
   my $rc = DB::Login::logon($id, $q->param('temp'));
   my $html = '<H1>Password Change</H1>';;
   if ($rc == -2)
   {
      $html .= 'Your temporary password is incorrect.<BR>';
      $html .= 'If you forgot your password, <A HREF=' . $CGI::Login::cgi . 
               '&action="Get Password">click here</A>.';
   }
   else
   {

      DB::Login::change_password($id, $q->param('newp'), 0);
      $html .= 'Your password has been successfuly changed.';
   }
}


sub forgot_password_form
{
   my($q) = shift;
   my $html = <<HTML;

<SCRIPT>
function valid()
{
   if (!document.passwd.id.value)
   {
      alert('Please enter your email address login id.');
      return false;
   }
   return true;
}
</SCRIPT>
<H1>Get New Password</H1>
<P>Please enter your login id :</P>
<FORM NAME=passwd onSubmit="return valid()">
   <INPUT TYPE=text NAME="id">
   <INPUT TYPE=submit NAME=action VALUE="Get Password">
   <INPUT TYPE="hidden" NAME="content" VALUE="login.html">
</FORM>
HTML
   return $html;
}

sub get_password
{
   my($q) = shift;
   my $id = $q->param('id');
   my $html = '<H1>Your Password</H1>';
   my $passwd = DB::Login::get_password($id);
   if ($passwd eq '')
   {
      $html .= '<P>Login id \'' . $id . '\' is incorrect.</P>';
      return $html;
   }

   require Mail::Mailer;
   my $type = 'sendmail';
   my $mailprog = Mail::Mailer->new($type);
   my %headers = (
      'To' => $id,
      'From' => 'info@elinkwebdesign.com',
      'Subject' => 'Tried Tested & True Login'
   );
   $mailprog->open(\%headers);
   print $mailprog
                  "Here is your password.\n\n" .
                  'Your login ID is ' . $id .
                  " and your password is '$passwd'.\n\n" .
                  'If you have any questions or concerns, please send ' .
                  'us an email at info@elinkwebdesign.com.';
   $mailprog->close;
   $html .= '<P>You will shortly receive an email with your password.</P>';
   return $html;
}

sub login_form
{
   my($q) = shift;
   my $html = '<H1>Login</H1>';
   $html .= '<FORM NAME="login" METHOD="post" onSubmit="return valid()">';
   $html .= <<HTML;
<SCRIPT LANGUAGE="Javascript">
function valid()
{
   lf = document.login;
   rc = false;
   if (lf.id.value == '' || lf.passwd.value == '')
      alert ('Please enter both your login and password.');
   else
      rc = true;
   return rc;
}

</SCRIPT>
<BR>
<H2>Enter your login information :</H2>
<TABLE BORDER=1 CELLPADDING=5>

<TR><TD>
<TABLE>
<TR><TD>Login :</TD><TD><INPUT NAME="id" TYPE="text"></TD>
<TR><TD>Password :</TD><TD><INPUT NAME="passwd" TYPE="password"></TD></TR>
<TR><TD><INPUT NAME="action" TYPE="submit" VALUE="Logon"></TD></TR>
</TABLE>
</TD></TR>

</TABLE>

<INPUT NAME="content" TYPE="hidden" VALUE="login.html">
</FORM>
HTML
   $html .= '<BR>' . $CGI::Login::registerHTML . $CGI::Login::passwordHTML;
   return $html;
}


sub setDB
{
   my($dbh) = shift;
   $DB::Login::dbh = $dbh;
   DB::Login::make($dbh);
   DB::User::make($dbh);
}


# hdr : 'header' => print output ONLY in header 
sub handleLoginRequest
{
   my($q, $hdr) = @_;
   my $html;
   ## if in header call
   if ($hdr && $hdr eq 'header')
   {
      if ($q->param('action') && $q->param('action') eq 'Logon')
      {
         my $rc = logon($q);
         return 'Incorrect Login Information.  Please try again.' if ($rc < 0);
      }
   }
   else
   {
      if ($q->param('register')) # register form
      {
         $html = register_form($q);
      }
      elsif ($q->param('action') && $q->param('action') eq 'Register')
      {
         $html = register($q);
      }
      elsif ($q->param('login')) # login form
      {
         $html = login_form($q);
      }
      elsif ($q->param('change_password')) # change password form
      {
         $html = change_password_form($q);
      }
      elsif ($q->param('action') && $q->param('action') eq 'Change Password')
      {
         $html = change_password($q);
      }
      elsif ($q->param('forgot_password')) # forgot password form
      {
         $html = forgot_password_form($q);
      }
      elsif ($q->param('action') && $q->param('action') eq 'Get Password') # get password
      {
         $html = get_password($q);
      }
   }
   return $html;
}

1;
