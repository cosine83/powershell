<#
.NAME
Install-WindowsTerminal.ps1

.PURPOSE
Installs Windows Terminal and its needed dependencies on Windows 10/2019/2022. It's much better than the default Command Prompt or PowerShell consoles.

.NOTES
Author: Justin Grathwohl
Date: 02/13/2025
Version: 1.0
#>

# Re-launch in PowerShell 7, compatible with remote push tools like PDQ where using requires won't work
If ($PSVersionTable.PSVersion.Major -ne 7) {
    Try {
        & "C:\Program Files\PowerShell\7\pwsh.exe" -File $PSCOMMANDPATH
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit
}

# PowerShell 7 requires loading the Appx module to
Import-Module Appx -UseWindowsPowerShell
# Set preference to hide progress bars due to performance impact in PowerShell 5.1
$ProgressPreference = "SilentlyContinue"

# WinGet - select the version you want to install, see https://github.com/microsoft/winget-cli/releases
# Windows Terminal - select the version you want to install, see https://github.com/microsoft/terminal/releases
$winGetVer = '1.9.25200'
$winGetLicenseFile = '7fdfd40ea2dc40deab85b69983e1d873_License1.xml'
$winTermVer = '1.22.10352.0'
$getWinVer = (Get-ComputerInfo).WindowsProductName

# Install dependencies for WinGet and Windows Terminal
# Detect and install Windows 10 depencencies
If($getWinVer -like "Windows 10*") {
    Invoke-WebRequest -Uri "https://github.com/microsoft/terminal/releases/download/v$($winGetVer)/Microsoft.WindowsTerminal_1.22.10352.0_8wekyb3d8bbwe.msixbundle_Windows10_PreinstallKit.zip" -Method Get -OutFile "$env:TEMP\WindowsTerminal_Windows10_PreinstallKit.zip"
    Expand-Archive -Path "$env:TEMP\WindowsTerminal_Windows10_PreinstallKit.zip" -DestinationPath "$env:TEMP\WindowsTerminal_Windows10_PreinstallKit" -Force
    $getWinTermDeps = Get-ChildItem -Path "$env:TEMP\WindowsTerminal_Windows10_PreinstallKit" | Where-Object {$_.Name -like "*x64*.appx" -or $_.Extension -is "msixbundle"}
    ForEach ($appPackage in $getWinTermDeps) {
        Add-AppxPackage -Path "$appPackage"
    }
    # Add-AppxPackage -Path "$env:TEMP\WindowsTerminal_Windows10_PreinstallKit\Microsoft.UI.Xaml.2.8_8.2501.31001.0_x64__8wekyb3d8bbwe.appx"
} Else {
    Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/download/v$($winGetVer)/DesktopAppInstaller_Dependencies.zip" -Method Get -OutFile "$env:TEMP\DesktopAppInstaller_Dependencies.zip"
    Expand-Archive -Path "$env:TEMP\DesktopAppInstaller_Dependencies.zip" -DestinationPath "$env:TEMP\DesktopInstaller_Dependencies" -Force
    $getWingetDeps = Get-ChildItem -Path "$env:TEMP\DesktopInstaller_Dependencies\x64" | Where-Object {$_.Name -like "*x64*.appx" -or $_.Extension -is "msixbundle"}
    ForEach ($appPackage in $getWingetDeps) {
        Add-AppxPackage -Path "$appPackage"
    }
    # Add-AppxPackage -Path "$env:TEMP\DesktopInstaller_Dependencies\x64\Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64.appx"
    # Add-AppxPackage -Path "$env:TEMP\DesktopInstaller_Dependencies\x64\Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64.appx"
    Add-AppPackage -Path "https://cdn.winget.microsoft.com/cache/source.msix."
}

# Download and install Microsoft.DesktopAppInstaller which includes winget in it
Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/download/v$($winGetVer)/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Method Get -OutFile "$env:TEMP\Microsoft.DesktopAppInstaller.WinGet.appx"
Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/download/v$($winGetVer)/$($winGetLicenseFile)" -Method Get -OutFile "$env:TEMP\license.xml"
Add-AppxPackage -Path "$env:TEMP\Microsoft.DesktopAppInstaller.WinGet.appx"

# Install Windows Terminal
Try{
    winget install --id Microsoft.WindowsTerminal -e --accept-source-agreements --accept-package-agreements
} Catch {
    Invoke-WebRequest -Uri "https://github.com/microsoft/terminal/releases/download/v$($winTermVer)/Microsoft.WindowsTerminal_$($winTermVer)_8wekyb3d8bbwe.msixbundle" -Method Get -Outfile "$env:TEMP\Microsoft.WindowsTerminal.appx"
    Add-AppxPackage -Path "$env:TEMP\Microsoft.WindowsTerminal.appx"
}
