#Requires microsoft-windows-netfx3-ondemand-package.cab from the install media under \Sources\SxS
#Syntax for SCCM Task Sequence only, unsure of usage outside of that
#Put in as a step after Windows setup and configuration as "Run PowerShell Script"

$currentLocation = Split-Path -Parent $MyInvocation.MyCommand.Path;
Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -Source $currentLocation -LimitAccess -All
