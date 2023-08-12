Import-Module ActiveDirectory
Import-Module NTFSSecurity

$user = Read-Host "Enter username you would like to look up"
$query = Get-ADUser $user -properties HomeDirectory
$HDrive = $query.HomeDirectory
$Admin = "BUILTIN\Administrators"
$Dadmins = "DOMAIN\Domain Admins"
$Sys = "NT AUTHORITY\SYSTEM"

Set-NTFSOwner -Path $HDrive -Account $Admin
Disable-NTFSAccessInheritance -Path $HDrive -RemoveInheritedAccessRules
Get-NTFSAccess -Path $HDrive | Remove-NTFSAccess
Add-NTFSAccess -Path $HDrive -Account PEPPERMILLCAS\$user, $Admin, $Dadmins, $Sys -AccessRights FullControl
