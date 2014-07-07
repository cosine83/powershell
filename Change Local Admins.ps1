Import-Module activedirectory

$ErrorActionPreference = "SiltentlyContinue"

$searchbase = "OU=Testing,DC=domain,DC=com"

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
			#ADSI fallback in case WinRM is unavailable
			Write-Host "WinRM unavailable, using ADSI..."
			Write-Host "Changing local admin password on $computer!"
			$LocalAdmin = [adsi]"WinNT://$computer/Administrator,user"
			$LocalAdmin.SetPassword($LocalAdminPW)
			$LocalAdmin.SetInfo()
			$LocalAdmin.InvokeSet("UserFlags",($LocalAdmin.UserFlags[0] -BOR 2 + 65536))
			$LocalAdmin.SetInfo()
			Write-Host "Local admin password is set and account disabled!"
			$LocalUser = [adsi]"WinNT://$computer/AG,user"
			If($LocalUser -eq $Null)
			{
			Write-Host "Creating new local admin user!"
			$NewUser = "AG"
			$LocalComputer = [adsi]"WinNT://$computer,computer"
			$CreateLocalUser = $LocalComputer.Create('User', $NewUser)
			$CreateLocalUser.SetPassword($LocalUserPW)
			$CreateLocalUser.SetInfo()
			$LocalUser.InvokeSet("UserFlags",($LocalUser.UserFlags[0] -BXOR 2 -BOR 65536))
			$LocalUser.SetInfo()
			([adsi]"WinNT://$computer/Administrators,group").Add("WinNT://$computer/AG")
			Write-Host "New user created, password set, and added to local admin group!"
			}
			Else
			{
			Write-Host "Local user already exists, setting password and user properties!"
			$LocalUser.SetPassword($LocalUserPW)
			$LocalUser.InvokeSet("UserFlags",($LocalUser.UserFlags[0] -BXOR 2 -BOR 65536))
			$LocalUser.SetInfo()
			Write-Host "Local user modified and password set!"
			}
		}
		else
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
	}
	else
	{
	Write-Host -ForegroundColor Red "Can't connect to $computer!"
	}
}