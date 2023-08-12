<#
.PURPOSE
The purpose of this script is to set the Windows update agent's configuration to a specific build of Windows. The client will not feature update or otherwise upgrade to a new bulid of Windows without manually doing so or removing the keys.

.LINKS

.TODO
- Add ability to have exceptions at runtime without predefining in the script

.NOTES
Created By: Justin Grathwohl
Date Created:
Date Updated:

#>

$wuPath = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
$wuPathcheck = Test-Path -Path $wuPath
If ($wuPathcheck) {
    New-ItemProperty -Path $wuPath -Name "ProductVersion" -Value "Windows 11" -Confirm:$false -Force
    New-ItemProperty -Path $wuPath -Name "TargetReleaseVersion" -Value "1" -Confirm:$false -PropertyType DWord -Force
    New-ItemProperty -Path $wuPath -Name "TargetReleaseVersionInfo" -Value "22H2" -Confirm:$false -Force
}