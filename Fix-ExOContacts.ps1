$aadConnect = Read-Host "Enter server name where AAD Connect is installed"

$ADSyncSession = New-PSSession $aadConnect
Import-Module ADSync -PSSession $ADSyncSession

$qUsers = Get-AdUser -Filter {Enabled -eq $true} -Properties mail

ForEach ($user in $qUsers) {
$mailAddress = $user.mail
$userName = $user.Name
	Try {
		Set-ADUser $user -Add @{targetAddress="SMTP:$mailAddress"}
	}
	Catch {
		Write-Host "$userName already has targetAddress set, check for Exchange Online mailbox"
	}
}
Write-Host "Starting AADC delta sync"
Start-ADSyncSyncCycle -PolicyType Delta

Write-Host "Waiting for 5 minutes..."
Start-Sleep -Seconds 300

$targetAddressException = Get-AdUser -Filter {Enabled -eq $true} -Properties targetAddress | Where {$_.targetAddress -notlike "*.onmicrosoft.com"}
$userException = $targetAddressException.SamAccountName

Write-Host "Clearing targetAddress field on non-Exchange Online users"
ForEach ($user in $userException) {
	Set-ADUser $user -Clear targetAddress
}

Write-Host "Starting final delta sync"
Start-ADSyncSyncCycle -PolicyType Delta
