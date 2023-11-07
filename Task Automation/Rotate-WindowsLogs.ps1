<#
.PURPOSE

.LINKS

.TODO

.NOTES
Created By: Justin Grathwohl
Date Created:
Date Updated:

#>

#Requires -Version 7

$Date = (Get-Date).AddDays(-7)
$logDate = Get-Date -Format yyyyMMddTHHmmssffff
Start-Transcript -Path "C:\temp\logrotate_$logDate.txt"

if(Test-Path "C:\inetpub\logs") {
	Get-ChildItem "C:\inetpub\logs\*.log" -Recurse | Where-Object {$_.LastWriteTime -lt $Date} | Compress-Archive -DestinationPath C:\temp\LogRotate-IIS-$logdate.zip -Force
	Get-ChildItem "C:\inetpub\logs\*.log" -Recurse | Where-Object {$_.LastWriteTime -lt $Date} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
	Write-Host -Background Black -Foreground Yellow "IIS logs cleaned"
}
else {
	Write-Host -Background Black -Foreground Yellow "No IIS logs to cleanup"
}

if(Test-Path "C:\Windows\System32\winevt\Logs") {
	Get-ChildItem "C:\Windows\System32\winevt\Logs\*.evtx" -Recurse | Where-Object {$_.LastWriteTime -lt $Date} | Compress-Archive -DestinationPath C:\temp\LogRotate-EVT-$logdate.zip -Force
	Get-ChildItem "C:\Windows\System32\winevt\Logs\*.evtx" -Recurse | Where-Object {$_.LastWriteTime -lt $Date} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
	Write-Host -Background Black -Foreground Yellow "Event Viewer logs cleaned"
}
else {
	Write-Host -Background Black -Foreground Yellow "No Event Viewer logs to cleanup"
}
if(Test-Path "C:\Windows\System32\LogFiles") {
	Get-ChildItem "C:\Windows\System32\LogFiles\*.log" -Recurse | Where-Object {$_.LastWriteTime -lt $Date} | Compress-Archive -DestinationPath C:\temp\LogRotate-Sys-$logdate.zip -Force
	Get-ChildItem "C:\Windows\System32\LogFiles\*.log" -Recurse | Where-Object {$_.LastWriteTime -lt $Date} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
	Write-Host -Background Black -Foreground Yellow "System logs cleaned"
}
else {
	Write-Host -Background Black -Foreground Yellow "No system logs to cleanup"
}
Stop-Transcript