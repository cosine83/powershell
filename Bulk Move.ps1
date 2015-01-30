#Bulk Move

Import-Module NTFSSecurity
Import-Module Activedirectory

$ErrorActionPreference = "Continue"
$Property = Read-Host "What property's file server are you migrating?"
if ($Property -eq "WV") {
	$OldServer = "wvfileserv1s"
	$OldDept = "\\$($OldServer)\d$\Shares"
	$OldHome = "\\$($OldServer)\h$\Shares"
	$NewServer = "wvfileserv1v"
	$NewDept = "\\$($NewServer)\d$\DeptShares"
	$ArchiveDept = "\\$($NewServer)\d$\_ArchiveOldFiles\Dept" 
	$DeptTapeArchive = "\\$($NewServer)\d$\_ArchiveOldFiles\Tape\Dept"
	$OldDeptArchive = "\\$($NewServer)\d$\DeptShares\*\_*Old*"
	$NewHome = "\\$($NewServer)\d$\Home"
	$ArchiveHome = "\\$($NewServer)\d$\_ArchiveOldFiles\Home"
	$HomeTapeArchive = "\\$($NewServer)\d$\_ArchiveOldFiles\Tape\Home"
	$OldHomeArchive = "\\$($NewServer)\d$\Home\_RemovedAccounts"
}
elseif ($Property -eq "RC") {
	$OldServer = "rcfileserv1s"
	$OldDept = "\\$($OldServer)\n$\DeptShares"
	$OldHome = "\\$($OldServer)\n$\Home Drives"
	$NewServer = "rcfileserv1v"
	$NewDept = "\\$($NewServer)\d$\DeptShares"
	$ArchiveDept = "\\$($NewServer)\d$\_ArchiveOldFiles\Dept" 
	$DeptTapeArchive = "\\$($NewServer)\d$\_ArchiveOldFiles\Tape\Dept"
	$OldDeptArchive = "\\$($NewServer)\d$\DeptShares\*\_*Old*"
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

robocopy $OldDept $NewDept /sec /mir /XO /XX /FFT /NFL /NDL /nc /ns /r:1 /w:10 /maxage:20110101
robocopy $OldHome $NewHome /sec /mir /XO /XX /FFT /NFL /NDL /nc /ns /r:1 /w:10 /maxage:20110101
robocopy $NewDept $ArchiveDept /sec /mir /XO /XX /FFT /NFL /NDL /nc /ns /r:1 /w:10 /minage:20101231 /maxage:20070101
robocopy $NewHome $ArchiveHome /sec /mir /XO /XX /FFT /NFL /NDL /nc /ns /r:1 /w:10 /minage:20101231 /maxage:20070101
robocopy $OldHome $ArchiveHome /sec /mir /XX /FFT /NFL /NDL /nc /ns /r:1 /w:10 /minage:20101231 /maxage:20070101
robocopy $OldDept $ArchiveDept /sec /mir /XX /FFT /NFL /NDL /nc /ns /r:1 /w:10 /minage:20101231 /maxage:20070101
robocopy $ArchiveDept $DeptTapeArchive /sec /mir /XX /FFT /NFL /NDL /nc /ns /r:1 /w:10 /minage:20061231
robocopy $ArchiveHome $HomeTapeArchive /sec /mir /XX /FFT /NFL /NDL /nc /ns /r:1 /w:10 /minage:20061231
Write-Host "Moving old archive folder to new archive location"
Get-ChildItem -Path $OldDeptArchive -Directory -Recurse | ForEach-Object { Move-Item $ArchiveDept -Force }
Get-ChildItem2 -Path $OldHomeArchive -Directory -Recurse | ForEach-Object { Move-Item $ArchiveHome -Force }
Write-Host "Move complete"

Write-Host "Removing duplicate and empty files and folders"
Get-ChildItem2 -Path $NewDept -Recurse | Where { !$_.PSIsContainer -and $_.LastWriteTime -lt $AgeLimit } | Remove-Item -Force
Get-ChildItem2 -Path $NewDept -Recurse | Where { $_.PSIsContainer -and (Get-ChildItem2 -Path $_.FullName -Recurse | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
Get-ChildItem2 -Path $NewHome -Recurse | Where { !$_.PSIsContainer -and $_.LastWriteTime -lt $AgeLimit } | Remove-Item -Force
Get-ChildItem2 -Path $NewHome -Recurse | Where { $_.PSIsContainer -and (Get-ChildItem2 -Path $_.FullName -Recurse | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
Get-ChildItem2 -Path $ArchiveHome -Recurse | Where { !$_.PSIsContainer -and $_.LastWriteTime -lt $ArchiveAgeLimit } | Remove-Item -Force
Get-ChildItem2 -Path $ArchiveHome -Recurse | Where { $_.PSIsContainer -and (Get-ChildItem2 -Path $_.FullName -Recurse | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
Get-ChildItem2 -Path $ArchiveDept -Recurse | Where { !$_.PSIsContainer -and $_.LastWriteTime -lt $ArchiveAgeLimit } | Remove-Item -Force
Get-ChildItem2 -Path $ArchiveDept -Recurse | Where { $_.PSIsContainer -and (Get-ChildItem2 -Path $_.FullName -Recurse | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
Write-Host "Script Complete"