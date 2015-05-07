Import-Module activedirectory

$ErrorActionPreference = "SilentlyContinue"

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
$baseAD = "OU=Computers,OU=Test,DC=domain,DC=com"
$Date = Get-Date -format MM.dd.yyyy

$Comp = Read-Host "Please define a computer"
$OU = Read-Host "Please define an OU"

$searchbase = $baseAD

if ($OU) { $searchbase = "OU=$OU,$searchbase" }
if ($Comp) { $searchbase = "CN=$Comp,$searchbase" }

$query = Get-ADComputer -Filter * -SearchBase $searchbase | Select Name | Sort Name
$computers = $query.Name

$LocalAdminPassword = Read-Host -AsSecureString "Please set the new local admin password"
$LocalUserPassword = Read-Host -AsSecureString "Please set the new local user password"
$LocalAdminPW = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($LocalAdminPassword))
$LocalUserPW = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($LocalUserPassword))

foreach ($computer in $computers)
{
    Write-Host "Connecting..."
	If(Test-Connection $computer -Count 1 -Quiet) #Check that PC is online
    {
        If(Test-WSMan $computer) #PC is online so check if WinRM enabled
        {
			#WinRM is enabled
			Write-Host "WinRM is enabled on $computer, proceeding..."
			Write-Host "Changing local admin password on $computer!"
			#This Invoke-Command script block must be all on a single line or it will not work
			Invoke-command -ComputerName $computer -Command { net user administrator $using:LocalAdminPW /active:no /passwordchg:no /expires:never }
			Write-Host "Local admin password is set and account disabled!"
			Write-Host "Creating new local admin user!"
			Invoke-command -ComputerName $computer -Command { net user ag $using:LocalUserPW /add /active:yes /passwordchg:no /expires:never }
			Invoke-command -ComputerName $computer -Command { net localgroup administrators $computer\ag /add }
			Write-Host "New user created, password set, and added to local admin group!"
		}
		else
		{
			Write-Host "WinRM is unavailable, please try the ADSI script."
			$offline = $computer | Out-File -Append -noClobber -filePath "C:\PowerShell Logs\Offline Computers $Date.csv" -width 20
			$offline
			Write-Host "Added to offline log file for $Date"
		}
	}
}
Write-Host "All offline computers have been written to the log file"
Write-Host "Opening log file..."
Invoke-Item "C:\PowerShell Logs\Offline Computers $Date.csv"
