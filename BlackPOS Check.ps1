#BlackPOS Checker script
#Created by: Justin Grathwohl, 2014

#Load Active Directory PowerShell Module
Import-Module activedirectory

#AD Path to search for computers to clean
$searchbase = "OU=Tertiary,OU=Secondary,OU=Top,DC=domain,DC=com"

#Get the list of computers to clean
$query = Get-ADComputer -Filter * -SearchBase $searchbase | Select Name | Sort Name
$computers = $query.Name


#This script utilizes SecureState's BlackPOS checker tool
#It is freeware but requires providing contact info
#Download here: http://engage.securestate.com/black-pos-malware-scanning

$exepath = "C:\Windows\System32"
set-alias blackpos "$exepath\black_pos_check.exe"

md -Path "C:\BlackPOS Log" -force

foreach ($computer in $computers)
{
	if (Test-Connection $computer -Count 1 -Quiet)
	{
		Write-Host "$computer is online!"
		Write-Host "Running BlackPOS Checker..."
		& blackpos $computer | Out-File -Force "C:\BlackPOS Log\$computer.txt"
		$file = "C:\BlackPOS Log\$computer.txt"
		foreach ($log in $file)
		{
			if (Get-Content $log | Select-String "not present" -quiet)
			{
			Write-Host -ForegroundColor Green "BlackPOS is not present!"
			}
			elseif (Get-Content $log | Select-String "confidence level" -quiet)
			{
			Write-Host -ForegroundColor Red "BlackPOS detected! Please clean the system!"
			}
			else
			{
			exit
			}
		}
	}
	else {
		Write-Host -ForegroundColor Yellow "$computer is offline."
	}
}