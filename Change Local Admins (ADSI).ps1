Import-Module activedirectory

$ErrorActionPreference = "Continue"

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
		Write-Host "Using ADSI..."
		Write-Host "Changing local admin password on $computer!"
		$LocalAdmin = [adsi]"WinNT://$computer/Administrator,user"
		$LocalAdmin.SetPassword($LocalAdminPW)
		$LocalAdmin.SetInfo()
		$LocalAdmin.InvokeSet("UserFlags",($LocalAdmin.UserFlags[0] -BOR 2))
		$LocalAdmin.SetInfo()
		Write-Host "Local admin password is set and account disabled!"
		$LocalComputer = ([adsi]"WinNT://$computer,computer")
		$LocalComputerUsers = ($LocalComputer.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)
		$LCUFound = $LocalComputerUsers -contains "AG"
		$LocalUser = [adsi]"WinNT://$computer/AG,user"
		If($LCUFound)
		{
		Write-Host "Local user already exists, setting password and user properties!"
		$LocalUser.SetPassword($LocalUserPW)
		$LocalUser.InvokeSet("UserFlags",($LocalUser.UserFlags[0] -BXOR 2))
		$LocalUser.SetInfo()
		Write-Host "Local user modified and password set!"		
		}
		Else
		{
		Write-Host "New local admin does not exist, creating!"
		$NewUser = "AG"
		$CreateLocalUser = $LocalComputer.Create('User', $NewUser)
		$CreateLocalUser.SetPassword($LocalUserPW)
		$CreateLocalUser.SetInfo()
		$LocalUser.InvokeSet("UserFlags",($LocalUser.UserFlags[0] -BXOR 2))
		$LocalUser.SetInfo()
		([adsi]"WinNT://$computer/Administrators,group").Add("WinNT://$computer/AG")
		Write-Host "New user created, password set, and added to local admin group!"
		}
	}
	else
	{
		Write-Host -ForegroundColor Red "Can't connect to $computer!"
	}
}