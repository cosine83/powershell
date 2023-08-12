$uptime = Get-Uptime
$uptime.Days
<#
If ($uptime.Days -ge 7){
    Write-Output "You need to reboot"
    $uptime.Days
} else {
    Write-Output "You don't need to reboot"
    $uptime.Days
} #>