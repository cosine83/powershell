#Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

$inactiveCompsOU = "OU=computers,OU=decom,DC=domain,DC=com"
$inactiveUsersOU = "OU=users,OU=decom,DC=domain,DC=com"
$todayDate = Get-Date
$compLogon = Search-ADAccount -AccountInactive -DateTime ((get-date).adddays(-90)) -ComputersOnly | Where {$_.LastLogonDate -ne "12/31/1600 4:00:00 PM" -and $_.LastLogonDate -ne $null} | Select Name,DistinguishedName,ObjectGUID,LastLogonDate,SamAccountName | Sort Name
$userLogon = Search-ADAccount -AccountInactive -DateTime ((get-date).adddays(-90)) -UsersOnly | Where {$_.DistinguishedName -like "*OU=Users,*" -and $_.DistinguishedName -notlike "*OU=Users,OU=Generic*" -and $_.LastLogonDate -ne "12/31/1600 4:00:00 PM" -and $_.LastLogonDate -ne $null} | Select Name,DistinguishedName,ObjectGUID,LastLogonDate,SamAccountName | Sort Name

Write-Host -Foreground Yellow -Background Black "Beginning computer search..."
ForEach ($computer in $compLogon) {
	$pingComp = Test-Connection $computer.Name -count 1 -quiet
	If ($pingComp -eq $false) {
		Set-ADComputer -Identity $computer.ObjectGUID -Description $computer.LastLogonDate
		Set-ADComputer -Identity $computer.ObjectGUID -Enabled $false
		Move-ADObject -Identity $computer.ObjectGUID -TargetPath $InactiveCompsOU
		Write-Host -Foreground Yellow -Background Black $computer.Name "disabled and moved, last logon noted in description field"
	}
	Else {
		Write-Host -Foreground Yellow -Background Black $computer.Name "pings but may need a reboot or domain re-join due to last reported domain logon"
	}
}

Write-Host -Foreground Yellow -Background Black "Beginning user search..."
ForEach ($user in $userLogon) {
	#Get-Mailbox -Identity $user.SamAccountName | Disable-Mailbox
	Set-ADUser -Identity $user.ObjectGUID -Office $user.LastLogonDate
	Set-ADUser -Identity $user.ObjectGUID -Enabled $false
	Move-ADObject -Identity $user.ObjectGUID -TargetPath $InactiveUsersOU
	Write-Host -Foreground Yellow -Background Black $user.DisplayName "disabled and moved"
}

Write-Host -Foreground Yellow -Background Black "Removing users and computers from groups..."
$gQuery = Get-ADGroup -Filter {Name -notlike "Domain Users" -and Name -notlike "Domain Computers"}
$dComps = Search-ADAccount -AccountDisabled -ComputersOnly -SearchBase $inactiveCompsOU
$dUsers = Search-ADAccount -AccountDisabled -UsersOnly -SearchBase $inactiveUsersOU

ForEach ($group in $gQuery) {
		Remove-ADGroupMember -Identity $group -Member $dUsers -Confirm:$false
		Remove-ADGroupMember -Identity $group -Member $dComps -Confirm:$false
}

$removeStale = Read-Host "Would you like to remove stale AD objects? (y`/n)"

If ($removeStale -eq "y") {
	$rcompLogon = Search-ADAccount -AccountDisabled -ComputersOnly -SearchBase $inactiveCompsOU | Where {(New-TimeSpan -Start $_.LastLogonDate -End $todayDate).Days -ge 180 -and $_.LastLogonDate -ne $null} | Select Name,DistinguishedName,ObjectGUID,LastLogonDate
	$ruserLogon = Search-ADAccount -AccountDisabled -UsersOnly -SearchBase $inactiveUsersOU | Where {(New-TimeSpan -Start $_.LastLogonDate -End $todayDate).Days -ge 180 -and $_.LastLogonDate -ne $null} | Select DisplayName,DistinguishedName,ObjectGUID,LastLogonDate
	
	ForEach ($rcomputer in $rcompLogon) {	
			Remove-ADObject -Identity $rcomputer.ObjectGUID -Recursive -Confirm:$false
		}
	ForEach ($ruser in $ruserLogon) {
			Remove-ADObject -Identity $ruser.ObjectGUID -Recursive -Confirm:$false
		}
	}
	$currentTime = Get-Date
	Write-Host -Foreground Yellow -Background Black "Script complete at" $currentTime
Else {
	$currentTime = Get-Date
	Write-Host -Foreground Yellow -Background Black "Script complete at" $currentTime
}
