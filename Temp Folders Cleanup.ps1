#PowerShell script to clean out temporary folders
#Created by Justin Grathwohl, 2014

#Load Active Directory PowerShell Module
#Requires Remote System Administration Tools to be installed and the AD module enabled
Import-Module activedirectory

#AD Path to search for computers to clean
$searchbase = "OU=Example,OU=Example,OU=Example,DC=Domain,DC=com"

#Credentials to use for network traversal if not running from an admin account, will need to add -Credentials to appropriate commands
#$credentials = Get-Credential -Message "Please provide administrator privileges" -UserName domain\username

#Set error display preference
$ErrorActionPreference = "SilentlyContinue"

#Get the list of computers to clean
$query = Get-ADComputer -Filter * -SearchBase $searchbase | Select Name | Sort Name
$computers = $query.Name

#Variable array for folders to clean for WinRM method, others can be added as needed
$tempRM = @("C:\Windows\Temp\*", "C:\Documents and Settings\*\Local Settings\temp\*", "C:\Users\*\Appdata\Local\Temp\*", "C:\Users\*\Appdata\Local\Microsoft\Windows\Temporary Internet Files\*")

#Set alias for PsExec to be able to be ran from PowerShell. Requires PsExec to on local machine
#Preferably in C:\Windows\system32 but where ever the executable is located should be fine
#Download PsTools here: http://technet.microsoft.com/en-us/sysinternals/bb896649.aspx
#Note that it requires an EULA to be accepted on first run on the local machine but has an -acceptEula switch to get around user input

#set-alias psexec "C:\Windows\system32\psexec.exe"

#Tests to see if WinRM is enabled on remote computer
#Copy and launch a batch file on remote computer using PsExec, if the test errors out
#This can be time consuming if you have a lot of computers to enable WinRM on
#In effect, this only really has to be done once per computer so this section can be commented out or cut into another script and used as needed
#SSL would be preferred for WinRM for security reasons but it requires setting up a non-self-signed certificate, which would be cumbersome for some to setup

<# foreach ($computer in $computers)
{
	if(Test-WSMan $computer){
		Write-Host "WinRM is already enabled on $computer!"
	}
	else {
        #launches PsExec, pushes out the batch file to the remote PC, and runs the batch file in an elevated command prompt
        & psexec -accepteula "\\$($computer)" -h -u administrator -p password -f -c "EnableWinRM.bat"
	}
}
 #>
#Operation to clear out temp files in specified folders
#The WinRM method requires winrm quickconfig -q to be run on host machines first
#The psexec command above should take care of enabling WinRM, including firewall exceptions
#The UNC method requires access to admin shares

foreach ($computer in $computers)
{
    Write-Host "Connecting..."
	If(Test-Connection $computer -Count 1 -Quiet) #Check that PC is online
    {
        If(Test-WSMan $computer) #PC is online so check if WinRM enabled
        {
            #WinRM is enabled, delete temp files via Invoke-Command
            Write-Host "WinRM is enabled on $computer, proceeding..."
            Write-Host "$computer - Deleting files via WinRM!"
            #This Invoke-Command script block must be all on a single line or it will not work
            Invoke-Command -ComputerName $computer -ScriptBlock { foreach ($folder in $using:tempRM) {Remove-Item -Path $folder -Recurse -Force} }
            Write-Host -ForegroundColor Green "$computer - Done!"
        }
        else
        {
            #WinRM not enabled, delete temp files via UNC path
            #UNC folder variable must be defined in the foreach loop or it will not populate computer names
            $tempUNC = @("\\$($computer)\c$\Windows\Temp\*", "\\$($computer)\c$\Documents and Settings\*\Local Settings\temp\*", "\\$($computer)\c$\Users\*\Appdata\Local\Temp\*", "\\$($computer)\c$\Users\*\Appdata\Local\Microsoft\Windows\Temporary Internet Files\*")
            Write-Host "WinRM is not enabled on $computer, proceeding..."
            Write-Host "$computer - Deleting files via UNC!"
            foreach ($folder in $tempUNC) {Remove-Item $folder -force -recurse}
            Write-Host -ForegroundColor Green "$computer - Done!"
        }#End inner If/Else
    }
    else
    {
        #PC was offline
        Write-Host -ForegroundColor Red "$computer - Offline!"
    }#End out If/Else
}#End foreach loop	