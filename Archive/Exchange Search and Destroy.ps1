# Search and/or destroy stuff in Exchange mailboxes
# Original Concept by John Grilli of Controle, LLC
# Modified by Justin Grathwohl of Peppermill Casinos, Inc.
# Originally used to search for IPM.Note.AxsExchange archive stubs/shortcuts in user mailboxes

#Load Exchange 2010 module and cmdlets so this will actually work remotely - requires Exchange Management Tools to be installed
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
Connect-ExchangeServer -auto -AllowCLobber

Write-Host "Checking if log folder exists and making it if not"
$Path = "C:\PowerShell Logs"
If (!(Test-Path -Path $Path )) {
	New-Item -ItemType Directory -Path $Path
}	
Else {
	Write-Host "Folder exists, proceeding with script execution"
}	

#This is required if the computer running the script hasn't been updated to PowerShell version 3 or newer
Write-Host "Checking PowerShell version..."
if ($PSVersionTable.PSVersion.Major -lt 3) {
	function Pause {
		Read-Host 'Press Enter to continue...' | Out-Null
	}
}
else {
	Write-Host "Powershell version greater than 3"
}

$Archive = Read-Host "Would you like to search users' online archive? `(Y/N`)"
$Exclude = Read-Host "Do you need to exclude any mailboxes? `(Y/N`)"
$TestOnly = Read-Host "Do you want to test before deleting? `(Y/N`)"
$Query = Read-Host "Enter your search terms `(Use KQL for complex searches`)"
$UserDumpPath = "C:\PowerShell Logs\UserDump.csv"
$UserArchiveDumpPath = "C:\PowerShell Logs\UserArchiveDump.csv"

if ($Archive -eq "y") {
	Write-Host "Setting to search users' archive"
	$GetUsers = Get-Mailbox -Archive -ResultSize Unlimited
}
else {
	$GetUsers = Get-Mailbox -ResultSize Unlimited
}

if ($Exclude -eq "y" -and $Archive -eq "y") {
	Write-Host "Dumping users with archives to CSV"
	$GetUsers = Get-Mailbox -Archive -ResultSize Unlimited | Select Alias | Sort Alias | Export-Csv -NoTypeInformation -Path "$UserArchiveDumpPath"
	$GetUsers
	Write-Host "Please edit the CSV file and remove any users you'd like to exclude before continuing. Do not continue before doing so."
	Invoke-Item "UserArchiveDumpPath"
	Pause
}
elseif ($Exclude -eq "y" -and $Archive -eq "n") {
	Write-Host "Dumping users to CSV"
	$GetUsers = Get-Mailbox -ResultSize Unlimited | Select Alias | Sort Alias | Export-Csv -NoTypeInformation -Path "$UserDumpPath"
	$GetUsers
	Write-Host "Please edit the CSV file and remove any users you'd like to exclude before continuing. Do not continue before doing so."
	Invoke-Item "$UserDumpPath"
	Pause
}
else {
	$GetUsers = Get-Mailbox -ResultSize Unlimited
}

if ($TestOnly -eq "y" -and $Exclude -eq "y" -and $Archive -eq "y") {
	Write-Host "Testing exclusions and searching archives"
	$Users = Import-Csv -Header Alias -Path "$UserArchiveDumpPath"
	foreach ($User in $Users) { 
		#Note that the -Append switch on Export-Csv will not work prior to Powershell v3 and the script will error out
		Search-Mailbox -Identity $User.Alias -SearchQuery "$Query" -EstimateResultOnly | Select DisplayName, Alias, ResultItemsCount, ResultItemsSize | Export-Csv -NoTypeInformation -Append -Path "C:\PowerShell Logs\StubArchiveDump.csv" 
	}
}
elseif ($TestOnly -eq "y" -and $Exclude -eq "y" -and $Archive -eq "n") {
	Write-Host "Testing exclusions and searching"
	$Users = Import-Csv -Header Alias -Path "$UserDumpPath"
	foreach ($User in $Users) {  
		#Note that the -Append switch on Export-Csv will not work prior to Powershell v3 and the script will error out
		Search-Mailbox -Identity $User.Alias -SearchQuery "$Query" -EstimateResultOnly | Select DisplayName, Alias, ResultItemsCount, ResultItemsSize | Export-Csv -NoTypeInformation  -Append -Path "C:\PowerShell Logs\StubDump.csv" 
	}
}
elseif ($TestOnly -eq "n" -and $Exclude -eq "y" -and $Archive -eq "n") { 
	Write-Host "Running delete on non-excluded"
	$Users = Import-Csv -Header Alias -Path "$UserDumpPath"
	foreach ($User in $Users) {  
		Search-Mailbox -Identity $User.Alias -SearchQuery "$Query" -DeleteContent -Confirm:$false
	}
}
elseif ($TestOnly -eq "y" -and $Exclude -eq "n" -and $Archive -eq "n") {
	Write-Host "Testing on user mailboxes"
	#Note that the -Append switch on Export-Csv will not work prior to Powershell v3 and the script will error out
	$GetUsers | Search-Mailbox -SearchQuery "$Query" -EstimateResultOnly | Select DisplayName, Alias, ResultItemsCount, ResultItemsSize | Sort Alias | Export-Csv -NoTypeInformation  -Append -Path "C:\PowerShell Logs\StubDump.csv" 
}
elseif ($TestOnly -eq "y" -and $Exclude -eq "n" -and $Archive -eq "y") {
	Write-Host "Testing on user archive mailboxes"
	#Note that the -Append switch on Export-Csv will not work prior to Powershell v3 and the script will error out
	$GetUsers | Search-Mailbox -SearchQuery "$Query" -EstimateResultOnly | Select DisplayName, Alias, ResultItemsCount, ResultItemsSize | Sort Alias | Export-Csv -NoTypeInformation  -Append -Path "C:\PowerShell Logs\StubArchiveDump.csv" 
}
elseif ($TestOnly -eq "n" -and $Exclude -eq "n" -and $Archive -eq "y") {
	Write-Host "Running delete on user archives"
	$GetUsers | Search-Mailbox -SearchQuery "$Query" -DeleteContent -Confirm:$false
}
else {
	Write-Host "Running delete on user mailboxes"
	$GetUsers | Search-Mailbox -SearchQuery "$Query" -DeleteContent -Confirm:$false
}
