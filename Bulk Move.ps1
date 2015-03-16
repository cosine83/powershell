#Bulk Move

Import-Module NTFSSecurity
Import-Module Activedirectory

$ErrorActionPreference = "Continue"

$Property = Read-Host "What property's file server are you migrating?"
if ($Property -eq "X1") {
	$HomeOwn = "\\oldfileserv1s\n$\Home Drives"
	$DeptOwn = "\\oldfileserv1s\n$\DeptShares\"
}
elseif ($Property -eq "X2") { 
	$HomeOwn = "\\oldfileserv1v\d$\Home\"
	$DeptOwn = "\\oldfileserv1v\d$\DeptShares\"
}
elseif ($Property -eq "X3") { 
	$HomeOwn = "\\oldfileserv1s\d$\Home Shares"
	$DeptOwn = "\\oldfileserv1s\d$\DeptShares\"
}
else { 
	Write-Host "Property designation invalid. Try again."
}

$TakeOwn = Read-Host "Do you need to take ownership of files and folders first?"
if ($TakeOwn -eq "y") {
Write-Host "Taking ownership of home folders"
takeown /a /r /d y /f $HomeOwn | Out-Null
Write-Host "Ownership given to local admins group"
Write-Host "Taking ownership of department folders"
takeown /a /r /d y /f $DeptOwn | Out-Null
Write-Host "Ownership given to local admins group"
}
else {
	Write-Host "Skipping ownership, proceeding to setting security permissions"
}

if ($Property -eq "X") {
	$OldServer = "oldfileserv1s"
	$OldDept = "\\$($OldServer)\d$\Shares"
	$OldHome = "\\$($OldServer)\h$\Shares"
	$NewServer = "newfileserv1v"
	$NewDept = "\\$($NewServer)\d$\DeptShares"
	$ArchiveDept = "\\$($NewServer)\d$\_ArchiveOldFiles\Dept" 
	$DeptTapeArchive = "\\$($NewServer)\d$\_ArchiveOldFiles\Tape\Dept"
	$OldDeptArchive = "\\$($NewServer)\d$\DeptShares\*\_*Old*"
	$NewHome = "\\$($NewServer)\d$\Home"
	$ArchiveHome = "\\$($NewServer)\d$\_ArchiveOldFiles\Home"
	$HomeTapeArchive = "\\$($NewServer)\d$\_ArchiveOldFiles\Tape\Home"
	$OldHomeArchive = "\\$($NewServer)\d$\Home\_RemovedAccounts"
}
elseif ($Property -eq "X2") {
	$OldServer = "oldfileserv1s"
	$OldDept = "\\$($OldServer)\n$\DeptShares"
	$OldHome = "\\$($OldServer)\n$\Home Drives"
	$OldMultiShares = "\\$($OldServer)\n$\MultiShares"
	$OldSystems = "\\$($OldServer)\n$\Systems"
	$OldPublic = "\\$($OldServer)\n$\Public"
	$OldHomeOwn = "\\$($OldServer)\n$\Home Drives\"
	$OldDeptOwn = "\\$($OldServer)\n$\DeptShares\"
	$NewServer = "newfileserv1v"
	$NewDept = "\\$($NewServer)\d$\DeptShares"
	$NewMultiShares = "\\$($NewServer)\s$\MultiShares"
	$NewSystems = "\\$($NewServer)\s$\Systems"
	$NewPublic = "\\$($NewServer)\d$\DeptShares\Public"
	$ArchiveDept = "\\$($NewServer)\d$\_ArchiveOldFiles\Dept" 
	$DeptTapeArchive = "\\$($NewServer)\d$\_ArchiveOldFiles\Tape\Dept"
	$OldDeptArchive = "\\$($NewServer)\d$\DeptShares\*\*Old*"
	$NewHome = "\\$($NewServer)\h$\HomeDrives"
	$ArchiveHome = "\\$($NewServer)\h$\_ArchiveOldFiles\Home"
	$HomeTapeArchive = "\\$($NewServer)\h$\_ArchiveOldFiles\Tape\Home"
	$OldHomeArchive = "\\$($NewServer)\h$\Home\_RemovedOldUsers"
}
else { 
	Write-Host "Property designation invalid. Try again."
	Exit
}

$AgeLimit = (Get-Date).AddDays(-1461)
$ArchiveAgeLimit = (Get-Date).AddDays(-2922)
$CompleteTime = Get-Date

Write-Host "Starting copy process"
robocopy $OldDept $NewDept /sec /secfix /timfix /mir /XO /XX /FFT /NFL /NDL /nc /ns /r:1 /w:3 /COPYALL /ZB
robocopy $OldHome $NewHome /sec /secfix /timfix /mir /XO /XX /FFT /NFL /NDL /nc /ns /r:1 /w:3 /COPYALL /ZB
robocopy $OldMultiShares $NewMultiShares /sec /secfix /timfix /mir /XO /XX /FFT /NFL /NDL /nc /ns /r:1 /w:3 /COPYALL /ZB
robocopy $OldSystems $NewSystems /sec /secfix /timfix /mir /XO /XX /FFT /NFL /NDL /nc /ns /r:1 /w:3 /ZB /COPYALL
Write-Host "Copying complete"

Write-Host "Arranging archives"
robocopy $NewDept $ArchiveDept /sec /secfix /timfix /mir /MOV /FFT /NFL /NDL /nc /ns /r:1 /w:3 /minage:20101231 /ZB
robocopy $NewHome $ArchiveHome /sec /secfix /timfix /mir /MOV /FFT /NFL /NDL /nc /ns /r:1 /w:3 /minage:20101231 /ZB
robocopy $OldHome $ArchiveHome /sec /secfix /timfix /mir /MOV /XX /XO /FFT /NFL /NDL /nc /ns /r:1 /w:3 /minage:20101231 /ZB
robocopy $OldDept $ArchiveDept /sec /secfix /timfix /mir /MOV /XX /XO /FFT /NFL /NDL /nc /ns /r:1 /w:3 /minage:20101231 /ZB
robocopy $ArchiveDept $DeptTapeArchive /sec /secfix /timfix /mir /MOV /FFT /NFL /NDL /nc /ns /r:1 /w:3 /minage:20061231 /ZB
robocopy $ArchiveHome $HomeTapeArchive /sec /secfix /timfix /mir /MOV /FFT /NFL /NDL /nc /ns /r:1 /w:3 /minage:20061231 /ZB
Write-Host "Archive arrangement complete"

Write-Host "Moving old archive files/folders to new archive location"
Get-ChildItem2 -Path $OldDeptArchive -Recurse | ForEach-Object { Move-Item $ArchiveDept -Force }
Get-ChildItem2 -Path $OldHomeArchive -Recurse | ForEach-Object { Move-Item $ArchiveHome -Force }
Write-Host "Move complete"

Write-Host "Removing duplicate and empty files and folders"
Get-ChildItem2 -Path $NewDept -Recurse | Where { $_.LastWriteTime -lt $AgeLimit } | Remove-Item -Recurse -Force
Get-ChildItem2 -Path $NewHome -Recurse | Where { $_.LastWriteTime -lt $AgeLimit } | Remove-Item -Recurse -Force
Get-ChildItem2 -Path $ArchiveHome -Recurse | Where { $_.LastWriteTime -lt $ArchiveAgeLimit } | Remove-Item -Recurse -Force
Get-ChildItem2 -Path $ArchiveDept -Recurse | Where { $_.LastWriteTime -lt $ArchiveAgeLimit } | Remove-Item -Recurse -Force
Write-Host "Removal complete"

Write-Host "Script Completed at $CompleteTime"
