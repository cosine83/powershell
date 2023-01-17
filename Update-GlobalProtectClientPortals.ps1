<#

.PURPOSE
The purpose of this script is to update existing installs of the GlobalProtect client to have the new VPN portals. Gateways are populated from the firewall side.

.DEPLOYMENT
To properly write to HKCU, the user will need to be logged in and the script executed in user context. If deploying via MDM solution, deploying as SYSTEM
results in the keys being written to HKU and not applied to the user. The HKLM keys seem to be loaded at install but have no impact on the application beyond redundancy.

.NOTES
- Restarting the service requires admin privileges or delegated permissions to the service for the user(s).
- Deploying via MDM in user context with admin will pop a UAC prompt if the service restarts are uncommented.
- If the service isn't restarted, the portal updates get applied on next login/restart or manual restart of the service.

#>

#Stop-Service -Name "PanGPS" -Force

$machineSettingsRegPath = "HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect\Settings"
$userSettingsRegPath = "HKCU:\SOFTWARE\Palo Alto Networks\GlobalProtect\Settings"
$bajaPortalUserPathTest = "$userSettingsRegPath\vpn.domain.com"
$moabPortalUserPathTest = "$userSettingsregPath\vpn2.domain.com"
$renoPortalUserPathTest = "$userSettingsregPath\vpn3.domain.com"
$bajaPortalMachinePathTest = "$machineSettingsRegPath\vpn.domain.com"
$moabPortalMachinePathTest = "$machineSettingsregPath\vpn2.domain.com"
$renoPortalMachinePathTest = "$machineSettingsregPath\vpn3.domain.com"

If(!(Test-Path $bajaPortalUserPathTest)) {
    New-Item $bajaPortalUserPathTest -Force
}

If(!(Test-Path $moabPortalUserPathTest)) {
    New-Item $moabPortalUserPathTest -Force
}

If(Test-Path $renoPortalUserPathTest) {
    Remove-Item $renoPortalUserPathTest -Force
}

If(!(Test-Path $bajaPortalMachinePathTest)) {
    New-Item $bajaPortalMachinePathTest -Force
}

If(!(Test-Path $moabPortalMachinePathTest)) {
    New-Item $moabPortalMachinePathTest -Force
}

If(Test-Path $renoPortalMachinePathTest) {
    Remove-Item $renoPortalMachinePathTest -Force
}

$testUserPanSettings = Get-ItemProperty "$userSettingsRegPath"
If ($testUserPanSettings.LastUrl -eq "vpn3.domain.com") {
    Set-ItemProperty -Path $userSettingsRegPath -Name "LastUrl" -Value "vpn.domain.com" -Force -Verbose
}

$testMachinePanSettings = Get-ItemProperty "$machineSettingsRegPath"
If ($testMachinePanSettings.LastUrl -eq "vpn3.domain.com") {
    Set-ItemProperty -Path $machineSettingsRegPath -Name "LastUrl" -Value "vpn.domain.com" -Force -Verbose
}

#Start-Service -Name "PanGPS"