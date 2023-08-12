#Enable a user in Lync
#Required to be run on the new Lync server or where the Lync PowerShell modules are
Import-Module lync*

$name = Read-Host "What is the person's name?"
$sipaddy = Read-Host "What is the person's e-mail address?"
$lyncserv = "lyncserv.domain.com"

Enable-CsUser -Identity "$name" -RegistrarPool "$lyncserv" -SipAddress "sip:$sipaddy"