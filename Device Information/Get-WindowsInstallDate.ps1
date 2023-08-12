$osInstallDate = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Output $osInstallDate.InstallDate