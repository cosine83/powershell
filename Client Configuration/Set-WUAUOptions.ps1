$wuPath = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
$wuauPath = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU"

$wuPathcheck = Test-Path -Path $wuPath

If ($wuPathcheck) {
    New-Item $wuPath -Force
    New-ItemProperty -Path $wuPath -Name "AllowAutoWindowsUpdateDownloadOverMeteredNetwork" -Value 1 -Confirm:$false -Force
    New-ItemProperty -Path $wuPath -Name "AUPowerManagement" -Value 1 -Confirm:$false -Force
    New-ItemProperty -Path $wuPath -Name "AutoRestartNotificationSchedule" -Value 120 -Confirm:$false -Force
    New-ItemProperty -Path $wuPath -Name "ScheduleImminentRestartWarning" -Value 30 -Confirm:$false -Force
    New-ItemProperty -Path $wuPath -Name "ScheduleRestartWarning" -Value 4 -Confirm:$false -Force
    New-ItemProperty -Path $wuPath -Name "SetAutoRestartNotificationConfig" -Value 1 -Confirm:$false -Force
    New-ItemProperty -Path $wuPath -Name "SetDisablePauseUXAccess" -Value 1 -Confirm:$false -Force
    New-ItemProperty -Path $wuPath -Name "SetRestartWarningSchd" -Value 1 -Confirm:$false -Force
    New-ItemProperty -Path $wuPath -Name "ProductVersion" -Value "Windows 11" -Confirm:$false -Force
    New-ItemProperty -Path $wuPath -Name "TargetReleaseVersion" -Value "1" -Confirm:$false -PropertyType DWord -Force
    New-ItemProperty -Path $wuPath -Name "TargetReleaseVersionInfo" -Value "22H2" -Confirm:$false -Force
    $wuAuPathcheck = Test-Path -Path $wuauPath
    If ($wuauPathCheck) {
        New-ItemProperty -Path $wuauPath -Name "AlwaysAutoRebootAtScheduledTime" -Value 1 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "AlwaysAutoRebootAtScheduledTimeMinutes" -Value 180 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "AUOptions" -Value 4 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "AUPowerManagement" -Value 1 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "AutoInstallMinorUpdates" -Value 1 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "DetectionFrequency" -Value 8 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "DetectionFrequencyEnabled" -Value 1 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "IncludeRecommendedUpdates" -Value 1 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "NoAUShutdownOption" -Value 0 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 0 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "NoAutoUpdate" -Value 0 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "RebootRelaunchTimeout" -Value 10 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "RebootRelaunchTimeoutEnabled" -Value 1 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "RescheduleWaitTime" -Value 1 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "RescheduleWaitTimeEnabled" -Value 1 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "ScheduledInstallDay" -Value 0 -Confirm:$false -Force
        New-ItemProperty -Path $wuauPath -Name "ScheduledInstallTime" -Value 23 -Confirm:$false -Force
    }
}