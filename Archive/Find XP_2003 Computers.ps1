#Find XP/2003 Computers and export to CSV

Write-Host "Checking if log folder exists and making it if not"
$Path = "C:\PowerShell Logs"
If (!(Test-Path -Path $Path ))
{
	New-Item -ItemType Directory -Path $Path
}	
Else
{
	Write-Host "Folder exists, proceeding with script execution"
}

$searchbase = "DC=domain,DC=com"
$computers = Get-ADComputer -Properties OperatingSystemVersion, SamAccountName -Filter { (Enabled -eq $true -and OperatingSystemVersion -eq "5.1 (2600)" -or OperatingSystemVersion -eq "5.2 (3790)") } -SearchBase $searchbase 

$computers | Select SamAccountName, OperatingSystemVersion | Export-Csv "C:\Powershell Logs\XP_2003 Computers.csv"