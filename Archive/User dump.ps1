Import-Module ActiveDirectory

$searchbase = "OU=groups,DC=domain,DC=com"
$Date = Get-Date -format MM.dd.yyyy
$Days = (Get-Date).AddDays(-180)
$users = Get-ADUser -Properties * -Filter {Enabled -eq $true} -SearchBase $searchbase | Select SamAccountName, LastLogonDate, Description

$users | Export-Csv "C:\PowerShell Logs\Users - $Date.csv"