$inactiveCompsOU = "OU=computers,OU=decom,DC=domain,DC=com"
$inactiveUsersOU = "OU=users,OU=decom,DC=domain,DC=com"
$todayDate = Get-Date
$compLogon = Search-ADAccount -AccountInactive -DateTime ((get-date).adddays(-90)) -ComputersOnly | Where {$_.LastLogonDate -ne "12/31/1600 4:00:00 PM" -and $_.LastLogonDate -ne $null} | Select Name,DistinguishedName,ObjectGUID,LastLogonDate
$userLogon = Search-ADAccount -AccountInactive -DateTime ((get-date).adddays(-90)) -UsersOnly | Where {$_.DistinguishedName -like "*OU=changeme*" -and $_.LastLogonDate -ne "12/31/1600 4:00:00 PM" -and $_.LastLogonDate -ne $null} | Select Name,DistinguishedName,ObjectGUID,LastLogonDate,samaccountname

Write-Host -Foreground Yellow -Background Black "Beginning computer search..."
ForEach ($computer in $compLogon) {
	$pingComp = Test-Connection $computer.Name -count 1 -quiet
	If ($pingComp -eq $false) {
		Set-ADComputer $computer -Location $computer.LastLogonDate
		Set-ADComputer $computer -Enabled $false
		Move-ADObject -Identity $computer.ObjectGUID -TargetPath $InactiveCompsOU
		Write-Host -Foreground Yellow -Background Black $computer.Name "disabled and moved, last logon noted in location field"
	}
	Else {
		Write-Host -Foreground Yellow -Background Black $computer.Name "pings but may need a reboot or domain re-join due to last reported domain logon"
	}
}

Write-Host -Foreground Yellow -Background Black "Beginning user search..."
ForEach ($user in $userLogon) {
	Set-ADUser $user -Office $user.LastLogonDate
	Set-ADUser $user -Enabled $false
	Move-ADObject -Identity $user.ObjectGUID -TargetPath $InactiveUsersOU
	Write-Host -Foreground Yellow -Background Black $user.DisplayName "disabled and moved"
}

Write-Host -Foreground Yellow -Background Black "Removing users and computers from groups..."
$gQuery = Get-ADGroup -Filter {Name -notlike "Domain Users" -and Name -notlike "Domain Computers"}
$aGroups = $gQuery.Name

ForEach ($group in $aGroups) {
	Get-ADGroupMember "$group" | Where { $_.ObjectClass -eq "user"} | ForEach-Object { Get-ADUser -Identity $_.distinguishedName -Properties * -SearchBase $inactiveUsersOU | Where {$_.Enabled -eq $false} } | ForEach-Object {
		$user = $_
		Remove-ADGroupMember -Identity "$group" -Member "$user" -Confirm:$false
	}
}

ForEach ($group in $aGroups) {
	Get-ADGroupMember "$group" | Where { $_.ObjectClass -eq "computer" } | ForEach-Object { Get-ADComputer -Identity $_.distinguishedName -Properties * -SearchBase $inactiveCompsOU | Where {$_.Enabled -eq $false} } | ForEach-Object {
		$computer = $_
		Remove-ADGroupMember -Identity "$group" -Member "$computer" -Confirm:$false
	}
}

$removeStale = Read-Host "Would you like to remove stale AD objects? (y`/n)"

If ($removeStale -eq y) {
	$rcompLogon = Search-ADAccount -AccountDisabled -ComputersOnly -SearchBase $inactiveCompsOU | Where {(New-TimeSpan -Start $_.LastLogonDate -End $todayDate).Days -ge 180} | Select Name,DistinguishedName,ObjectGUID,LastLogonDate
	$ruserLogon = Search-ADAccount -AccountDisabled -UsersOnly -SearchBase $inactiveUsersOU | Where {(New-TimeSpan -Start $_.LastLogonDate -End $todayDate).Days -ge 180} | Select DisplayName,DistinguishedName,ObjectGUID,LastLogonDate
	
	ForEach ($rcomputer in $rcompLogon) {	
			Remove-ADObject $computer.ObjectGUID -Recursive
		}
	}
	ForEach ($ruser in $ruserLogon) {
			Remove-ADObject $user.ObjectGUID -Recursive
		}
	}
}
Else {
	$currentTime = Get-Date
	Write-Host -Foreground Yellow -Background Black "Script complete at" $currentTime
}
