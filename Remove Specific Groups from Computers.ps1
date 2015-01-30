#Remove specific groups from disabled computers

#Import AD module
Import-Module ActiveDirectory

#$ErrorActionPreference = "SilentlyContinue"

$EntGroups = "OU=groups,DC=domain,DC=com"
$inactiveOU = "OU=disabled accounts,DC=domain,DC=com"
$Days = (Get-Date).AddDays(-90)
$groups = @("Group1","Group2")
#Change below to Get-ADUser if you want to remove groups from a user
$computers = Get-ADComputer -Properties Name,Enabled,LastLogonDate -Filter {(Enabled -eq "False" -and LastLogonDate -lt $Days)} -SearchBase $inactiveOU

foreach ($group in $groups) {
	Get-ADGroupMember -Identity $group -SearchBase $EntGroups
	foreach ($computer in $computers) {
		Remove-ADGroupMember -Identity $group -Members $computer.ObjectGUID -Confirm:$false
	}
}