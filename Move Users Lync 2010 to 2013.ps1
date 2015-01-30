#Migrate Lync users from old to newlync
#Required to be run on the new Lync server or where the Lync PowerShell modules are
Import-Module lync*

#Move users from Lync 2010 to Lync 2013

Get-CsUser -Filter {RegistrarPool -eq "oldlync.domain.com"} | Move-CsUser -Target "newlync.domain.com" -Confirm:$false