#PowerShell script to copy files to multiple remote computers using UNC paths
#Created by Justin Grathwohl, 2014

#Load Active Directory PowerShell Module
Import-Module activedirectory

#Where to look in AD for computers to copy files to
$searchbase = "OU=Secondary,OU=Primary,DC=domain,DC=com"

#AD query to get, filter, sort, and load into a variable
$query = Get-ADComputer -Filter * -SearchBase $searchbase | Select Name | Sort Name
$computers = $query.Name

#Loop going through each computer in the OU and performing the actions below.
foreach ($computer in $computers)
{
    Write-Host "Connecting..."
	If(Test-Connection $computer -Count 1 -Quiet) #Check that PC is online
    {
		Write-Host "Copying file to $computer!"
		$ServPath = "\\server\file.txt"
		#Alternate $ServPath variable in array form if multiple files need to be copied, comma separated with spaces
		#$ServPath = @("\\server\file.txt")
		$ClientPath = "\\$($computer)\c$\file.txt"
		#Alternate $ClientPath variable in array form if multiple files need to be copied, comma separated with spaces
		#$ClientPath = @("\\$($computer)\c$\file.txt")
		Copy-Item -Path $ServPath -Destination $ClientPath -Force
		Write-Host -ForegroundColor Green "Finished copying file to $computer!"
		Write-Host "Terminating notepad on $computer!"
		(Get-WmiObject Win32_Process -ComputerName $computer | ?{ $_.ProcessName -match "notepad" }).Terminate()
		Write-Host -ForegroundColor Green "notepad successfully terminated on $computer."
	}
	else
    {
        #PC was offline
        Write-Host -ForegroundColor Red "$computer is offline!"
    }#End out If/Else
}#End foreach loop	