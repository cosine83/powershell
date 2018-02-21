$inactiveCompsOU = "OU=computers,OU=decom,DC=domain,DC=com"
$inactiveUsersOU = "OU=users,OU=decom,DC=domain,DC=com"
$todayDate = Get-Date
$compLogon = Get-ADComputer -Properties Name,DistinguishedName,LastLogonTimestamp,ObjectGUID -Filter {Enabled -eq $true} | Where {[datetime]::FromFileTime($_.LastLogonTimestamp) -ne "12/31/1600 4:00:00 PM"} | Select Name,DistinguishedName,ObjectGUID,@{Name="LastLogonTimestamp";Expression={[datetime]::FromFileTime($_.LastLogonTimestamp)}}
$userLogon = Get-ADUser -Filter {Enabled -eq $true} -Properties DisplayName,DistinguishedName,LastLogonTimestamp,ObjectGUID | Where {$_.DistinguishedName -like "*OU=that,*" -and $_.DistinguishedName -notlike "*OU=notthat*" -and [datetime]::FromFileTime($_.LastLogonTimestamp) -ne "12/31/1600 4:00:00 PM"} | Select DisplayName,DistinguishedName,ObjectGUID,@{Name="LastLogonTimestamp";Expression={[datetime]::FromFileTime($_.LastLogonTimestamp)}}

Write-Host -Foreground Yellow -Background Black "Beginning computer search..."
ForEach ($computer in $compLogon) {
	$pingComp = Test-Connection $computer.Name -count 1 -quiet
	$ctimeSpan = (New-TimeSpan -Start $computer.LastLogonTimestamp -End $todayDate).Days
	If ($ctimeSpan -ge 90 -and $pingComp -eq $false) {
		Set-ADComputer $computer -Location $computer.LastLogonTimestamp
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
	$utimeSpan = (New-TimeSpan -Start $user.LastLogonTimestamp -End $todayDate).Days
	If ($utimeSpan -ge 90) {
		Set-ADUser $user -Office $user.LastLogonTimestamp
		Set-ADUser $user -Enabled $false
		Move-ADObject -Identity $user.ObjectGUID -TargetPath $InactiveUsersOU
		Write-Host -Foreground Yellow -Background Black $user.DisplayName "disabled and moved"
	}
	Else {
		Write-Host -Foreground Yellow -Background Black $User.DisplayName "has logged in within the last 90 days"
	}
}

Write-Host -Foreground Yellow -Background Black "Removing users and computers from groups..."
$gQuery = Get-ADGroup -Filter {Name -notlike "Domain Users" -and Name -notlike "Domain Computers"}
$aGroups = $gQuery.Name

ForEach ($group in $aGroups) {
	Get-ADGroupMember "$group" | Where { $_.ObjectClass -eq "user"} | ForEach-Object { Get-ADUser -Identity $_.distinguishedName -Properties * | Where {$_.Enabled -eq $false} } | ForEach-Object {
		$user = $_
		Remove-ADGroupMember -Identity "$group" -Member "$user" -Confirm:$false
	}
}

ForEach ($group in $aGroups) {
	Get-ADGroupMember "$group" | Where { $_.ObjectClass -eq "computer" } | ForEach-Object { Get-ADComputer -Identity $_.distinguishedName -Properties * | Where {$_.Enabled -eq $false} } | ForEach-Object {
		$computer = $_
		Remove-ADGroupMember -Identity "$group" -Member "$computer" -Confirm:$false
	}
}

$removeStale = Read-Host "Would you like to remove stale AD objects? (y`/n)"

If ($removeStale -eq y) {
	$rcompLogon = Get-ADComputer -Properties Name,DistinguishedName,LastLogonTimestamp,ObjectGUID -Filter {Endabled -eq $false} -SearchBase $inactiveCompsOU | Where {[datetime]::FromFileTime($_.LastLogonTimestamp) -ne "12/31/1600 4:00:00 PM"} | Select Name,DistinguishedName,ObjectGUID,@{Name="LastLogonTimestamp";Expression={[datetime]::FromFileTime($_.LastLogonTimestamp)}}
	$ruserLogon = Get-ADUser -Filter {Enabled -eq $false} -Properties DisplayName,DistinguishedName,LastLogonTimestamp,ObjectGUID -SearchBase $inactiveUsersOU | Where {$_.DistinguishedName -like "*OU=that,*" -and $_.DistinguishedName -notlike "*OU=notthat*" -and [datetime]::FromFileTime($_.LastLogonTimestamp) -ne "12/31/1600 4:00:00 PM"} | Select DisplayName,DistinguishedName,ObjectGUID,@{Name="LastLogonTimestamp";Expression={[datetime]::FromFileTime($_.LastLogonTimestamp)}}
	
	ForEach ($rcomputer in $rcompLogon) {	
		$rctimeSpan = (New-TimeSpan -Start $rcomputer.LastLogonTimestamp -End $todayDate).Days
		If ($rctimeSpan -ge 180) {
			Remove-ADObject $computer.ObjectGUID -Recursive
		}
	}
	ForEach ($ruser in $ruserLogon) {
		$rutimeSpan = (New-TimeSpan -Start $ruser.LastLogonTimestamp -End $todayDate).Days
		If ($rutimeSpan -ge 180) {
			Remove-ADObject $user.ObjectGUID -Recursive
		}
	}
}
Else {
	$currentTime = Get-Date
	Write-Host -Foreground Yellow -Background Black "Script complete at" $currentTime
}
