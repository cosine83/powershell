$inactiveCompsOU = "OU=computers,OU=decom,DC=domain,DC=com"
$inactiveUsersOU = "OU=users,OU=decom,DC=domain,DC=com"
$todayDate = Get-Date
$compLogon = Get-ADComputer -Properties Name,DistinguishedName,LastLogon,ObjectGUID -Filter {Endabled -eq $true} | Where {[datetime]::FromFileTime($_.LastLogon) -ne "12/31/1600 4:00:00 PM"} | Select Name,DistinguishedName,ObjectGUID,@{Name="LastLogon";Expression={[datetime]::FromFileTime($_.LastLogon)}}
$userLogon = Get-ADUser -Filter {Enabled -eq $true} -Properties DisplayName,DistinguishedName,LastLogon,ObjectGUID | Where {$_.DistinguishedName -like "*OU=Users,*" -and $_.DistinguishedName -notlike "*OU=Users,OU=Generic*" -and [datetime]::FromFileTime($_.LastLogon) -ne "12/31/1600 4:00:00 PM"} | Select DisplayName,DistinguishedName,ObjectGUID,@{Name="LastLogon";Expression={[datetime]::FromFileTime($_.LastLogon)}}

Write-Host -Foreground Yellow -Background Black "Beginning computer search..."
ForEach ($computer in $compLogon) {
	$ctimeSpan = (New-TimeSpan -Start $computer.LastLogon -End $todayDate).Days
	If ($ctimeSpan -ge 90) {
		Set-ADComputer $computer -Location $computer.LastLogon
		Set-ADComputer $computer -Enabled $false
		Move-ADObject -Identity $computer.ObjectGUID -TargetPath $InactiveCompsOU
		Write-Host -Foreground Yellow -Background Black $computer.Name "disabled and moved"
	}
}

Write-Host -Foreground Yellow -Background Black "Beginning user search..."
ForEach ($user in $userLogon) {
	$utimeSpan = (New-TimeSpan -Start $user.LastLogon -End $todayDate).Days
	If ($utimeSpan -ge 90) {
		Set-ADUser $user -Office $user.LastLogon
		Set-ADUser $user -Enabled $false
		Move-ADObject -Identity $user.ObjectGUID -TargetPath $InactiveUsersOU
		Write-Host -Foreground Yellow -Background Black $user.DisplayName "disabled and moved"
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
	$rcompLogon = Get-ADComputer -Properties Name,DistinguishedName,LastLogon,ObjectGUID -Filter {Endabled -eq $false} -SearchBase $inactiveCompsOU | Where {[datetime]::FromFileTime($_.LastLogon) -ne "12/31/1600 4:00:00 PM"} | Select Name,DistinguishedName,ObjectGUID,@{Name="LastLogon";Expression={[datetime]::FromFileTime($_.LastLogon)}}
	$ruserLogon = Get-ADUser -Filter {Enabled -eq $false} -Properties DisplayName,DistinguishedName,LastLogon,ObjectGUID | Where {$_.DistinguishedName -like "*OU=Users,*" -and $_.DistinguishedName -notlike "*OU=Users,OU=Generic*" -and [datetime]::FromFileTime($_.LastLogon) -ne "12/31/1600 4:00:00 PM"} | Select DisplayName,DistinguishedName,ObjectGUID,@{Name="LastLogon";Expression={[datetime]::FromFileTime($_.LastLogon)}}
	
	ForEach ($rcomputer in $rcompLogon) {	
		$rctimeSpan = (New-TimeSpan -Start $rcomputer.LastLogon -End $todayDate).Days
		If ($rctimeSpan -ge 180) {
			Remove-ADObject $computer.ObjectGUID -Recursive
		}
	}
	ForEach ($ruser in $ruserLogon) {
		$rutimeSpan = (New-TimeSpan -Start $ruser.LastLogon -End $todayDate).Days
		If ($rutimeSpan -ge 180) {
			Remove-ADObject $user.ObjectGUID -Recursive
		}
	}
}
Else {
	$currentTime = Get-Date
	Write-Host -Foreground Yellow -Background Black "Script complete at" $currentTime
}
