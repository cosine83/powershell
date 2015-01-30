#Bulk unlock AD account
Import-Module ActiveDirectory

#Search root
$searchbase = "DC=domain,DC=com"
$lookup = Get-ADUser -Filter * -searchbase $searchbase

$lookup | Unlock-ADAccount