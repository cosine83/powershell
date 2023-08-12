#Bulk Change Home Directory

Import-Module Activedirectory

$BaseAD = "DC=domain,DC=com"
$SearchBase = $BaseAD

$ErrorActionPreference = "SilentlyContinue"
$Property = Read-Host "What property's users home shares are you changing?"
if ($Property -eq "X") { 
	$SearchBase = "OU=Users,OU=property1,$searchbase"
	$FilterPath = "\\domain\olddfs\HomeShares*"
	$OldHome = "\\oldfileserv\n$\Home"
	$NewHome = "\\newfileserv\n$\Home"
	$OldPath = "\\domain\olddfs\Home"
	$NewPath = "\\domain\newdfs\Home"
}
elseif ($Property -eq "X2") { 
	$SearchBase = "OU=Users,OU=property2,$searchbase"
	$FilterPath = "\\domain\dfs\HomeShares*"
	$OldHome = "\\oldfileserv\n$\Home"
	$NewHome = "\\fileserv2\d$\Home"
	$OldPath = "\\domain\olddfs\Home"
	$NewPath = "\\domain\dfs\HomeShares"
}
else { 
	Write-Host "Property designation invalid. Try again."
}

$GetH = Get-ADUser -Properties HomeDirectory -Filter * -SearchBase $SearchBase | Where {$_.HomeDirectory -like $FilterPath} | Sort SamAccountName | Select SamAccountName
$Users = $GetH | ForEach-Object {$_.SamAccountName.Trim("@{}")}

ForEach ($user in $Users) {
	Write-Host "Setting user's home folder location"
	Set-ADUser $user -HomeDirectory "$OldPath\$user" -HomeDrive H:
	Write-Host "Checking if user folder exists and creating it if not"
	$Path = "$OldHome\$user"
	If (!(Test-Path -Path $Path ))
	{
		Write-Host "Creating user folder"
		New-Item -ItemType Directory -Path $Path
		Write-Host "Folder created, setting security permissions"
	}
	Else
	{
		Write-Host "User folder exists, setting security permissions"
	}
	Write-Host "Setting security permissions on user's home folder"
	$ACL = Get-ChildItem "$OldHome\$user" -Directory -Recurse | Get-Acl
	$ACL.SetAccessRuleProtection($true, $true)
	$ACL.SetOwner([System.Security.Principal.NTAccount] "Administrators")
	#The below will remove all existing ACLs on the objects before adding
	#$ACL.Access | ForEach { [Void]$ACL.RemoveAccessRule($_) }
	$ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
	$ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("domain\Domain Admins","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
	$ACL.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("domain\$user","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
	Set-Acl "$OldHome\$user" $ACL
	Write-Host "Permissions set"
}