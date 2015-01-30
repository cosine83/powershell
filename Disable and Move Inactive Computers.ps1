#Import AD module
Import-Module ActiveDirectory

$ErrorActionPreference = "SilentlyContinue"

$searchbase = "DC=domain,DC=com"
$EntGroups = "OU=Groups,DC=domain,DC=com"
$groups = Get-ADGroup -Properties Name -Filter * -searchbase $EntGroups
$inactiveOU = "OU=Disabled Accounts,DC=domain,DC=com"
$Days = (Get-Date).AddDays(-90)
$computers = Get-ADComputer -Properties * -Filter {LastLogonDate -lt $Days} -SearchBase $searchbase
$DisabledComps = Get-ADComputer -Properties Name,Enabled,LastLogonDate -Filter {(Enabled -eq "False" -and LastLogonDate -lt $Days)} -SearchBase $inactiveOU

#Move inactive computer accounts to your inactive OU
foreach ($computer in $computers) {	
	Set-ADComputer $computer -Location $computer.LastLogonDate | Set-ADComputer $computer -Enabled $false 
	Move-ADObject -Identity $computer.ObjectGUID -TargetPath $inactiveOU
	#Remove group memberships
	foreach ($group in $groups) {
		Remove-ADGroupMember -Identity $group -Members $computer.ObjectGUID -Confirm:$false
	}
}
#Optionally remove stale computer objects from AD
#Remove stale computer accounts older than 365 days
#$RemoveStale = Get-ADComputer -Filter * -SearchBase $DisabledComps | Where-Object {$_.Location -gt (Get-Date).AddDays(-365) -and $_.Location -lt (Get-Date).AddDays(-180)}
#$RemoveStale | Remove-ADObject