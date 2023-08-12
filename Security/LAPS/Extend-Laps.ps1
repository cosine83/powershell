<#
.Synopsis
Generates, stores, and gets randomly generated passwords for AD computers. This would be supplemental to Microsoft's LAPS since it can only manage one local admin account.
There is also additional functionality to set a new local admin

.DESCRIPTION
This set of functions will use a .NET assemply to generate a password of 30 characters, store it in a computer's AD object extensionAttribute1, then stores the date added/changed in extensionAttribute2. 
This is supplemental to Microsoft's LAPS since it can only manage one local admin account.
This set of functions requires the Active Directory and DSACL modules - Install-Module DSACL

.NOTES
Name: Extend-Laps
Author: Justin Grathwohl
Version: 1.2
DateUpdated:2021-04-13

.PARAMETER ComputerName
The name of the AD-joined computer

.EXAMPLE
Store-AdmPassword -ComputerName test01

.Description
Creates and stores a 30 character, randomly generated password for AD-joined computer test01

.EXAMPLE
Get-AdmPassword -ComputerName test01

.Description
Outputs the computer and the password set in extensionAttribute1

.EXAMPLE
Set-AdmPassword -ComputerName test01

.Description
Reads the AD stored password and sets it on the built-in local administrator account and removes the user flag so the passsword is able to expire. Can change BXOR to BOR to make it not expire.
#>

[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
Import-Module ActiveDirectory
Import-Module DSACL

Function New-ExtAdmPwd() {
	Param(
	[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[Microsoft.ActiveDirectory.Management.ADComputer]$ComputerName
	)
	$Date = Get-Date
	$GenPass = [System.Web.Security.Membership]::GeneratePassword(30,5)
	Set-ADComputer -Identity $ComputerName -replace @{extensionAttribute1="$GenPass"}
	Set-ADComputer -Identity $ComputerName -replace @{extensionAttribute2="$Date"}
}
	
Function Get-ExtAdmPwd() {
	Param(
	[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[Microsoft.ActiveDirectory.Management.ADComputer]$ComputerName
	)
	Get-ADComputer -Identity $ComputerName -Properties extensionAttribute1,extensionAttribute2 | Select-Object @{Name="Computer";Expression={$_.Name}}, @{Name="Password";Expression={$_.extensionAttribute1}}, @{Name="Set On";Expression={$_.extensionAttribute2}}
}

Function Set-ExtAdmPwd() {
	Param (
	[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[Microsoft.ActiveDirectory.Management.ADComputer]$ComputerName
		
	)
	$StoredPwd = Get-ADComputer -Identity $ComputerName -Properties extensionAttribute1
	$AdmPwd = ConvertTo-SecureString $StoredPwd.extensionAttribute1 -AsPlainText -Force
	$Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdmPwd))
	$BuiltinAdmin = [adsi]"WinNT://$ComputerName/Administrator,user" #Change Username to which ever local user account you wish
	$BuiltinAdmin.SetPassword($Password)
	$BuiltinAdmin.SetInfo()
	$BuiltinAdmin.InvokeSet("UserFlags",($BuiltinAdmin.UserFlags[0] -BXOR 65536))
	$BuiltinAdmin.CommitChanges()
	$BuiltinAdmin.SetInfo()
}

Function Set-ExtAdmPwdPermissions() {
	Param (
	[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[Microsoft.ActiveDirectory.Management.ADComputer]$ComputerName
	)

	$PwdFields = Get-ADComputer -Identity $ComputerName -Properties extensionAttribute1,extensionAttribute2
	$PwdFields | ForEach-Object 
	dsacls "OU=Organization,DC=domain,DC=com" /I:S /G "CORP\Service_Desk:RP;extensionAttribute1;computer" "CORP\Service_Desk:RP;pwdLastSet;computer" "CORP\Service_Desk:RP;extensionAttribute2;computer"
}

Function New-LocalAdmPwd() {
	Param (
	[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[Microsoft.ActiveDirectory.Management.ADComputer]$ComputerName

	)

	$Date = Get-Date
	$GenPass = [System.Web.Security.Membership]::GeneratePassword(30,5)
	$AdmPwd = ConvertTo-SecureString $GenPass -AsPlainText -Force
	$Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdmPwd))
	$BuiltinAdmin = [adsi]"WinNT://$ComputerName/Administrator,user" #Change Username to which ever local user account you wish
	$BuiltinAdmin.SetPassword($Password)
	$BuiltinAdmin.SetInfo()
	$BuiltinAdmin.SetDescription($Date)
	$BuiltinAdmin.SetInfo()
	$BuiltinAdmin.InvokeSet("UserFlags",($BuiltinAdmin.UserFlags[0] -BXOR 65536))
	$BuiltinAdmin.CommitChanges()
	$BuiltinAdmin.SetInfo()
}