#Find and move PSTs by user

$ErrorActionPreference = "SilentlyContinue"
$uQuery = Get-ADUser -Filter * -Properties HomeDirectory | Sort SamAccountName

ForEach ($user in $uQuery) {
	$Folder = $user.SamAccountName
	If (!(Test-Path "\\server\share\$Folder")) {
		New-Item "\\server\share\$Folder" -ItemType Directory
	}
	Else {
		Write-Host "user folder already exists"
	}
	If (!(Test-Path $user.HomeDirectory)) {
		Write-Host "User home directory does not exist"
	}
	Else{ 
		Get-ChildItem $user.HomeDirectory -Recurse -Filter *.pst | ForEach-Object { robocopy $_.DirectoryName "\\server\share\$Folder" *.pst /MOVE }
	}
}
