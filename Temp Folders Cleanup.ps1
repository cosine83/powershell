#PowerShell script to clean out temporary folders
#Created by Justin Grathwohl, 2014

#Load Active Directory PowerShell Module
Import-Module activedirectory

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

#AD Path to search for computers to clean
$baseAD = "OU=Computers,OU=Test,DC=domain,DC=com"
$Date = Get-Date -format MM.dd.yyyy

$Comp = Read-Host "Please define a computer"
$OU = Read-Host "Please define an OU"
$askNoGPI = Read-Host "Are the computers under the No GP Inheritance OU? (y/n)"

$searchbase = $baseAD

if ($askNoGPI -eq 'y') { $searchbase = "OU=No GP Inheritance,$searchbase" }
if ($OU) { $searchbase = "OU=$OU,$searchbase" }
if ($Comp) { $searchbase = "CN=$Comp,$searchbase" }

#Credentials to use for network traversal if not running from an admin account, will need to add -Credentials to appropriate commands
#$credentials = Get-Credential -Message "Please provide administrator privileges" -UserName domain\username

#Set error display preference
$ErrorActionPreference = "SilentlyContinue"

#Get the list of computers to clean
$query = Get-ADComputer -Filter * -SearchBase $searchbase | Select Name | Sort Name
$computers = $query.Name

#Variable array for folders to clean for WinRM method, others can be added as needed
$tempRM = @("C:\Windows\Temp\*", "C:\Documents and Settings\*\Local Settings\temp\*", "C:\Users\*\Appdata\Local\Temp\*", "C:\Users\*\Appdata\Local\Microsoft\Windows\Temporary Internet Files\*", "C:\Windows\SoftwareDistribution\Download", "C:\Windows\System32\FNTCACHE.DAT")

#Operation to clear out temp files in specified folders
#The WinRM method requires winrm quickconfig -q to be run on host machines first
#The psexec command above should take care of enabling WinRM, including firewall exceptions
#The UNC method requires access to admin shares, still need to figure out how to get it to fail over to it

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
            Invoke-Command -ComputerName $computer -ScriptBlock { foreach ($folder in $using:tempRM) {Remove-Item -Path $folder -Recurse -Force} }
            Write-Host -ForegroundColor Green "$computer - Done!"
        }
        else
        {
            #WinRM not enabled, delete temp files via UNC path
            #UNC folder variable must be defined in the foreach loop or it will not populate computer names
            $tempUNC = @("\\$($computer)\c$\Windows\Temp\*", "\\$($computer)\c$\Documents and Settings\*\Local Settings\temp\*", "\\$($computer)\c$\Users\*\Appdata\Local\Temp\*", "\\$($computer)\c$\Users\*\Appdata\Local\Microsoft\Windows\Temporary Internet Files\*", "\\$($computer)\c$\Windows\SoftwareDistribution\Download", "\\$($computer)\c$\Windows\System32\FNTCACHE.DAT")
			Write-Host "WinRM is not enabled on $computer, proceeding..."
            Write-Host "$computer - Deleting files via UNC!"
            foreach ($folder in $tempUNC) {Remove-Item $folder -force -recurse}
            Write-Host -ForegroundColor Green "$computer - Done!"
        }#End inner If/Else
    }
    else
    {
        #PC was offline
        $offline = $computer | Out-File -Append -noClobber -filePath "C:\PowerShell Logs\Cleanup - Offline Computers $Date.csv" -width 20
		Write-Host -ForegroundColor Red "Can't connect to $computer"
		$offline
		Write-Host "Added to offline log file for $Date"
    }#End out If/Else
}#End foreach loop

Write-Host "All offline computers have been written to the log file"
Write-Host "Opening log file..."
Invoke-Item "C:\PowerShell Logs\Cleanup - Offline Computers $Date.csv"
