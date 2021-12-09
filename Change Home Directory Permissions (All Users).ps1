Import-Module ActiveDirectory
Import-Module NTFSSecurity

$ErrorActionPreference = "SilentlyContinue"

$query = Get-ChildItem "\\ttfiler02\rdrive\Inbox\Dom Cota" -Directory -Recurse
$Admin = "BUILTIN\Administrators"
$Dadmins = "CORP\Domain Admins"
$Sys = "NT AUTHORITY\SYSTEM"
$SD = "CORP\Service_Desk"

foreach ($folder in $query) {
	Set-NTFSOwner -Path $folder.FullName -Account $Admin
	Disable-NTFSAccessInheritance -Path $folder.FullName -RemoveInheritedAccessRules
	Get-NTFSAccess -Path $folder.FullName | Remove-NTFSAccess
	Add-NTFSAccess -Path $folder.FullName -Account $Admin, $Dadmins, $Sys, $SD -AccessRights FullControl
	Write-Output "Changed Inbox folder permissions on $($folder.FullName)"
}
