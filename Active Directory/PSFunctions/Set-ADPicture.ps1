<#
.Synopsis
Gets and sets the picture for a user's AD and Outlook profile

.DESCRIPTION
This will get and set the AD and Outlook picture of the defined user. Pictures need to be 96x96 in JPEG format. Higher resolution pictures will be cropped and resized to square and results won't always be optimal. 
This requires the AD PowerShell module and either the Exchange 2010/2013 management tools to be installed locally or a remote session loaded to an Exchange server.

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ExchangeServer/PowerShell -Authentication Kerberos
Import-PSSession $session

.NOTES
Name: Set-ADPicture
Author: Justin Grathwohl
Version: 1.0
DateUpdated:2016-06-23

.PARAMETER User
The name of the AD user.

.PARAMETER Path
Path to the picture. Needs to be the full path, does not like mapped network drive letter usage but will accept full UNC paths including DFS paths.

.EXAMPLE
Get-ADProfilePicture -User jsmith

.Description
This will return the username and useless info about the picture. Mainly used to validate if they have a picture set or not since the thumbnailPhoto attribute will be empty without one.

.EXAMPLE
Set-ADProfilePicture -User jsmith -Path C:\pics\pic.jpg

.Description
This will set the AD picture for the user jsmith. Remember to use quotes for spaces in the path name.

.EXAMPLE
Set-OutlookPicture -User jsmith -Path \\server\folder\pic.jpg

.Description
Set's the picture that will appear in Outlook for the user jsmith. Must be JPEG.
#>

Function Get-ADProfilePicture() {
	Param(
	[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[Microsoft.ActiveDirectory.Management.ADAccount]$User
		
	)
	Get-ADUser $User -Properties thumbnailPhoto | Select-Object @{Name="User";Expression={$_.Name}}, @{Name="Photo";Expression={$_.thumbnailPhoto}}
}

Function Set-ADProfilePicture() {
	Param(
	[Parameter(Mandatory=$true,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[Microsoft.ActiveDirectory.Management.ADAccount]$User,
		[Parameter(Mandatory=$true,Position=1)]
		[String]$Path
	)
	$Photo = ([Byte[]] $(Get-Content -Path $Path -Encoding Byte -ReadCount 0))
	Set-ADUser $User -Replace @{thumbnailPhoto=$photo}
}

Function Set-OutlookPicture() {
	Param(
	[Parameter(Mandatory=$true,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[String]$User,
		[Parameter(Mandatory=$true,Position=1)]
		[String]$Path
	)
	Import-RecipientDataProperty -Identity $User -Picture -FileData ([Byte[]] $(Get-Content -Path $Path -Encoding Byte -ReadCount 0))
}