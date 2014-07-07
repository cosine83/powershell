Import-Module activedirectory

$ErrorActionPreference = "SilentlyContinue"

$searchbase = "OU=IT Testing,OU=IT,OU=Computers,OU=Aliante,DC=aliantegaming,DC=com"

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
			Write-Host "WinRM is unavailable, please run the ADSI script."
		}
	}
	else
	{
		Write-Host -ForegroundColor Red "Can't connect to $computer!"
	}
}