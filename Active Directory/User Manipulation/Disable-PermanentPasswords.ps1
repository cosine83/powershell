<#
.PURPOSE
The purpose of this script is to look through AD user accounts flagged to never have their passwords expire and unflag it.

.LINKS

.TODO
- Add ability to have exceptions at runtime without predefining in the script

.NOTES
Created By: Justin Grathwohl
Date Created: 2016
Date Updated: 2023

#>

$neverExpPassUsers = Search-ADAccount -SearchBase "OU=Users,OU=Organization,DC=domain,DC=local" -PasswordNeverExpires | Where-Object { $_.Enabled -eq $true -and $_.DistinguishedName -notlike "*Service Accounts*" } | Select-Object Name,SamAccountName,DistinguishedName | Sort-Object Name
$neverExpPassUsers | ForEach-Object { Set-ADUser -Identity $_.SamAccountName -PasswordNeverExpires $false -WhatIf }