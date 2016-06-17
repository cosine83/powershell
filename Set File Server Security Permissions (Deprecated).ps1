#Set Secuirty permissions on file server

#Due to long file names and paths limitations, this script may require the use of the NTFSSecurity PowerShell module
#Module can be found here: https://ntfssecurity.codeplex.com/
#Put the folder in your PowerShell module path before running this script
#Once installed, change any Get-ChildItem to Get-ChildItem2
#Import-Module NTFSSecurity

$ErrorActionPreference = "SilentlyContinue"
$Property = Read-Host "What property's permissions are you changing?"
if ($Property -eq "X") {
	$HomeOwn = "\\fileserv1\h$\Home\"
	$DeptOwn = "\\fileserv1\d$\Dept\"
}
elseif ($Property -eq "X2") { 
	$HomeOwn = "\\fileserv2\d$\Home\"
	$DeptOwn = "\\wvfileserv2\d$\Dept\"
}
elseif ($Property -eq "X3") { 
	$HomeOwn = "\\fileserv3\d$\Home"
	$DeptOwn = "\\fileserv3\d$\Dept\"
}
else { 
	Write-Host "Property designation invalid. Try again."
}

#Note, the takeown process can and will take a long time, depending on how many files are present
Write-Host "Taking ownership of home folders"
takeown /a /r /d y /f $HomeOwn | Out-Null
Write-Host "Ownership given to local admins group"
Write-Host "Taking ownership of department folders"
takeown /a /r /d y /f $DeptOwn | Out-Null
Write-Host "Ownership given to local admins group"

if ($Property -eq "RC") { 
	$HomePath = Get-ChildItem -Path "\\fileserv1\d$\Home\" -Directory -Recurse
	$DeptPath = Get-ChildItem -Path "\\fileserv1\d$\Dept\" -Directory -Recurse
}
elseif ($Property -eq "WV") { 
	$HomePath = Get-ChildItem -Path "\\fileserv2\d$\Home\" -Directory -Recurse
	$DeptPath = Get-ChildItem -Path "\\wvfileserv2\d$\Dept\" -Directory -Recurse

}
elseif ($Property -eq "PCI") { 
	$HomePath = Get-ChildItem -Path "\\fileserv3\d$\Home" -Directory -Recurse
	$DeptPath = Get-ChildItem -Path "\\fileserv3\d$\Dept\" -Directory -Recurse
}
else { 
	Write-Host "Property designation invalid. Try again."
}

ForEach ($folder in $HomePath) {
	Write-Host "Setting permissions on home folders"
	$ACL = Get-Acl "$folder"
	$ACL.SetAccessRuleProtection($true, $true)
	$ACL.SetOwner([System.Security.Principal.NTAccount] "Administrators")
	$ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
	$ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("DomainName\Domain Admins","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
	Set-Acl "$folder" $ACL
	Write-Host "Setting permissions completed"
}

ForEach ($folder in $DeptPath) {
	Write-Host "Setting permissions on department folders"
	$ACL = Get-ChildItem "$folder" -Directory -Recurse | Get-Acl
	$ACL.SetAccessRuleProtection($true, $true)
	$ACL.SetOwner([System.Security.Principal.NTAccount] "Administrators")
	$ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
	$ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("DomainName\Domain Admins","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
	Set-Acl "$folder" $ACL
	Write-Host "Setting permissions completed"
}
