#Load Active Directory PowerShell Module
Import-Module activedirectory

#AD Path to search for computers to clean
$searchbase = "OU=Example,OU=Example,OU=Example,DC=Domain,DC=com"

#Get the list of computers to clean
$query = Get-ADComputer -Filter * -SearchBase $searchbase | Select Name | Sort Name
$computers = $query.Name

<# Set alias for PsExec to be able to be ran from PowerShell. Requires PsExec to on local machine, 
Preferably in C:\Windows\system32 but where ever the executable is located should be fine
Download PsTools here: http://technet.microsoft.com/en-us/sysinternals/bb896649.aspx
Note that it requires a EULA to be accepted on first run on the local machine but has an -acceptEula switch to get around user input #>

set-alias psexec "C:\Windows\system32\psexec.exe"

<# Test to see if WinRM is enabled on remote computer
Copy and launch a batch file on remote computer using PsExec, if the test errors out #>

foreach ($computer in $computers)
{
	if(Test-WSMan $computer -ErrorAction SilentlyContinue){
		Write-Host "WinRM is enabled on $computer!"
	}
	else {
        #launches PsExec, pushes out the batch file to the remote PC, and runs the batch file in an elevated command prompt
		& psexec -accepteula "\\$($computer)" -h -u administrator -p password -f -c "EnableWinRM.bat"
	}
}