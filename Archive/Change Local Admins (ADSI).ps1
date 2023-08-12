Import-Module activedirectory

$ErrorActionPreference = "Continue"

Write-Host "Checking if log folder exists and making it if not"
$Path = "C:\PowerShell Logs"
If (!(Test-Path -Path $Path )) {
	New-Item -ItemType Directory -Path $Path
}	
Else {
	Write-Host "Folder exists, proceeding with script execution"
}	

$Date = Get-Date -format MM.dd.yyyy

$query = Get-ADComputer -Filter {Enabled -eq $true} | Select Name | Sort Name
$computers = $query.Name

$LocalAdminPassword = Read-Host -AsSecureString "Please set the new local admin password"
$LocalUserPassword = Read-Host -AsSecureString "Please set the new local user password"
$LocalAdminPW = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($LocalAdminPassword))
$LocalUserPW = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($LocalUserPassword))

foreach ($computer in $computers) {
	Write-Host "Connecting..."
	If(Test-Connection $computer -Count 1 -Quiet) {
		Write-Host "Changing local admin password on $computer"
		$LocalComputer = ([adsi]"WinNT://$computer,computer")
		$LocalUser = [adsi]"WinNT://$computer/pcteam,user"
		$LocalComputerUsers = ($LocalComputer.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)
		$LocalComputerUsersDesc = ($LocalComputer.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Description)
		$LCUExists = $LocalComputerUsers -contains "pcteam"
		$LCAExists = $LocalComputerUsers -contains "Administrator"
		$DescFound = $LocalComputerUsersDesc  -contains "Built-in account for administering the computer/domain"
		If ($LCUExists -eq $true -and $DescFound -eq $true -and $LCAExists -eq $false) {
			Write-Host "Found renamed built-in admin account, renaming..."
			$LocalUser.psbase.rename("Administrator")
		}
		$LocalAdmin = [adsi]"WinNT://$computer/Administrator,user"
		$LocalAdmin.SetPassword($LocalAdminPW)
		$LocalAdmin.SetInfo()
		$LocalAdmin.InvokeSet("UserFlags",($LocalAdmin.UserFlags[0] -BOR 2))
		$LocalAdmin.CommitChanges()
		$LocalAdmin.SetInfo()
		Write-Host "Local admin password is set and account disabled"
		$LCU = ($LocalComputer.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)
		$LCUFound = $LCU -contains "pcteam"
		If($LCUFound) {
			Write-Host "Local user already exists, setting password and user properties"
			$LocalUser.SetPassword($LocalUserPW)
			$LocalUser.InvokeSet("UserFlags",($LocalUser.UserFlags[0] -BXOR 65600))
			$LocalUser.CommitChanges()
			$LocalUser.SetInfo()
			Write-Host "Local user modified and password set"		
		}
		Else {
		Write-Host "New local admin does not exist, creating"
		$NewUser = "pcteam"
		$CreateLocalUser = $LocalComputer.Create('User', $NewUser)
		$CreateLocalUser.SetPassword($LocalUserPW)
		$CreateLocalUser.SetInfo()
		$LocalUser.InvokeSet("UserFlags",($LocalUser.UserFlags[0] -BXOR 65600))
		$LocalUser.CommitChanges()
		$LocalUser.SetInfo()
		([adsi]"WinNT://$computer/Administrators,group").Add("WinNT://$computer/pcteam")
		Write-Host "New user created, password set, and added to local admin group"
		}
	}
	else {
		$offline = $computer | Out-File -Append -noClobber -filePath "C:\PowerShell Logs\Local Admins - Offline Computers $Date.csv" -width 20
		Write-Host -ForegroundColor Red "Can't connect to $computer"
		$offline
		Write-Host "Added to offline log file for $Date"
	}
}
Write-Host "Operation completed on $Date"
Write-Host "All offline computers have been written to the log file"
Write-Host "Opening log file..."
Invoke-Item "C:\PowerShell Logs\Local Admins - Offline Computers $Date.csv"
