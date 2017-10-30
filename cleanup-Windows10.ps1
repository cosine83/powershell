#Windows 10 Cleanup Script PoSh version

#Set PowerShell environment variables so their paths are resolveable for PowerShell since it does not support CMD environment variables

$SYSTEMROOT = [System.Environment]::ExpandEnvironmentVariables("%SYSTEMROOT%")
$USERPROFILE = [System.Environment]::ExpandEnvironmentVariables("%USERPROFILE%")
$LOCALAPPDATA = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%")
$PROGRAMDATA = [System.Environment]::ExpandEnvironmentVariables("%PROGRAMDATA%")

$Confirm = Read-Host "Have you checked the script to validate you will not lose anything you want to keep? [y`/n]"

If ($Confirm = "y") {

	Write-Host -Background Black -Foreground Yellow "Disabling some services"

	Stop-Service DiagTrack -Force
	Stop-Service diagnosticshub.standardcollector.service -Force
	Stop-Service dmwappushservice -Force
	Stop-Service WMPNetworkSvc -Force
	Stop-Service WSearch -Force

	Set-Service DiagTrack -StartupType Disabled
	Set-Service diagnosticshub.standardcollector.service -StartupType Disabled
	Set-Service dmwappushservice -StartupType Disabled
	# Set-Service RemoteRegistry -StartupType Disabled
	# Set-Service TrkWks -StartupType Disabled
	Set-Service WMPNetworkSvc -StartupType Disabled
	Set-Service WSearch -StartupType Disabled
	# Set-Service SysMain -StartupType Disabled

	Write-Host -Background Black -Foreground Yellow "Disabling some scheduled tasks"
	
	#Disable-ScheduledTask "SmartScreenSpecific"
	Disable-ScheduledTask "Microsoft Compatibility Appraiser"
	Disable-ScheduledTask "ProgramDataUpdater"
	Disable-ScheduledTask "StartupAppTask"
	Disable-ScheduledTask "Consolidator"
	Disable-ScheduledTask "KernelCeipTask"
	Disable-ScheduledTask "UsbCeip"
	Disable-ScheduledTask "Uploader"
	Disable-ScheduledTask "FamilySafetyUpload"
	Disable-ScheduledTask "OfficeTelemetryAgentLogOn"
	Disable-ScheduledTask "OfficeTelemetryAgentFallBack"
	Disable-ScheduledTask "Office 15 Subscription Heartbeat"

	Write-Host -Background Black -Foreground Yellow "Disabling telemetry and data collection..."
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Value 1
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MRT" -Name "DontOfferThroughWUAU" -Value 1
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableUAR" -Value 1
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener" -Name "Start" -Value 0
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\SQMLogger" -Name "Start" -Value 0

	Write-Host -Background Black -Foreground Yellow "Disabling advertising ID usage"
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
	
	$SmarScreen = Read-Host "Would you like to disable SmartScreen Filter for web content? [y`/n] (NOT Recommended for security)"
	If ($SmarScreen -eq "y"){
		Write-Host -Background Black -Foreground Yellow "SmartScreen Filter disabled"
		Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" -Name "EnableWebContentEvaluation" -Value 0
		Disable-ScheduledTask "SmartScreenSpecific"
	}
	Else {
		Write-Host -Background Black -Foreground Yellow "SmartScreen Filter enabled"
		Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" -Name "EnableWebContentEvaluation" -Value 1
	}
	
	$LocalContent = Read-Host "Allow websites to show locally relevant content based on language list? [y`/n]"
	If ($LocalContent -eq "n") {
		Write-Host -Background Black -Foreground Yellow "Forbidding website access to language list"
	}
	Else {
		Write-Host -Background Black -Foreground Yellow "Allowing website access to language list"
	}

	Write-Host -Background Black -Foreground Yellow "Disabling WiFi Sense HotSpot Sharing"
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "value" -Value 0
	Set-ItemProperty -Path "Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "value" -Value 0

	Write-Host -Background Black -Foreground Yellow "Changing Windows Updates to schedule restarts and disable P2P downloads"
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Value 1
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0

	Write-Host -Background Black -Foreground Yellow "Removing search box from taskbar"
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0

	Write-Host -Background Black -Foreground Yellow "Disable jump lists for XAML apps"
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 0

	Write-Host -Background Black -Foreground Yellow "Set Windows Explorer to use This PC view"
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1

	Write-Host -Background Black -Foreground Yellow "Removing built-in apps..."

	Get-AppxPackage *3DBuilder* | Remove-AppxPackage
	Get-AppxPackage *Getstarted* | Remove-AppxPackage
	Get-AppxPackage *WindowsAlarms* | Remove-AppxPackage
	Get-AppxPackage *WindowsCamera* | Remove-AppxPackage
	Get-AppxPackage *bing* | Remove-AppxPackage
	Get-AppxPackage *MicrosoftOfficeHub* | Remove-AppxPackage
	Get-AppxPackage *OneNote* | Remove-AppxPackage
	Get-AppxPackage *people* | Remove-AppxPackage
	Get-AppxPackage *WindowsPhone* | Remove-AppxPackage
	Get-AppxPackage *photos* | Remove-AppxPackage
	# Get-AppxPackage *SkypeApp* | Remove-AppxPackage
	Get-AppxPackage *solit* | Remove-AppxPackage
	Get-AppxPackage *WindowsSoundRecorder* | Remove-AppxPackage
	Get-AppxPackage *windowscommunicationsapps* | Remove-AppxPackage
	Get-AppxPackage *zune* | Remove-AppxPackage
	# Get-AppxPackage *WindowsCalculator* | Remove-AppxPackage
	# Get-AppxPackage *WindowsMaps* | Remove-AppxPackage
	Get-AppxPackage *Sway* | Remove-AppxPackage
	Get-AppxPackage *CommsPhone* | Remove-AppxPackage
	Get-AppxPackage *ConnectivityStore* | Remove-AppxPackage
	Get-AppxPackage *Microsoft.Messaging* | Remove-AppxPackage
	Get-AppxPackage *Facebook* | Remove-AppxPackage
	Get-AppxPackage *Twitter* | Remove-AppxPackage
	# Get-AppxPackage *Drawboard PDF* | Remove-AppxPackage

	Write-Host -Background Black -Foreground Yellow "Adding some minor tweaks"

	Write-Host -Background Black -Foreground Yellow "Setting show hidden files and folders"
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
	Write-Host -Background Black -Foreground Yellow "Setting show hidden OS files"
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuper" -Value 1
	Write-Host -Background Black -Foreground Yellow "Setting show file extensions"
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0

	$OneDrive = Read-Host "Would you like to remove OneDrive? [y`/n]"

	If ($OneDrive -eq "y") {
		Start-Process -Path $SYSTEMROOT\SYSWOW64\ONEDRIVESETUP.EXE -ArgumentList ('/UNINSTALL')
		Remove-Item "$USERPROFILE\OneDrive -Recurse" -Force
		Remove-Item "$LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force
		Remove-Item "$PROGRAMDATA\Microsoft OneDrive" -Recurse -Force
		Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder" -Name "Attributes" -Value 0
		Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder" -Name Atributes -Value 0
		Write-Host "OneDrive has been removed"
	}
	Else {
		Write-Host -Background Black -Foreground Yellow "It is recommended to restart your computer."
		$Restart = Read-Host "Would you like to restart your computer? [y`/n]"
		If ($Restart -eq "y") {
			Restart-Computer
		}
		Else {
			Write-Host -Background Black -Foreground Yellow "Please restart at your convenience."
		}
	}
}
Else {
	Write-Host -Background Black -Foreground Yellow "Please check the script before running!"
}
