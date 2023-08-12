$getAdmins = Get-LocalGroupMember "Administrators"
$computerName = $env:COMPUTERNAME
$localAdmins = ($getAdmins.Name | Where-Object { $_ -notlike "*Admins*" -and $_ -notlike "*ADM*" -and $_ -notlike "*$computerName*" }) -Join ", "
$localAdmins