#Rename AD Groups

Import-Module ActiveDirectory
$ErrorActionPreference = "Continue"

$searchabse = "OU=groups,DC=domain,DC=com"
$GetGroups = Get-ADGroup -Properties DistinguishedName -Filter * -searchbase $searchabse 
$groups = $GetGroups | ForEach-Object {$_.Name.Trim("@{*derp}")}

foreach ($gotgroup in $groups) {
	$GroupName = "Users - $gotgroup"
	Rename-ADObject -Identity $group.DistinguishedName -NewName $GroupName
	$GetGroups | ForEach-Object {Set-ADGroup -Identity $_.DistinguishedName -SamAccountName $GroupName}
}