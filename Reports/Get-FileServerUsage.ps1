<#
.Synopsis


.DESCRIPTION


.NOTES
Name: Get-FileServerUsage.ps1
Author: Justin Grathwohl
Version: 1.0
DateUpdated:2023-11-05

.TODO

#>
Start-Transcript

Write-Output "Loading required modules"
If (Get-Module -ListAvailable -Name "NTFSSecurity") {
	Import-Module NTFSSecurity
    Write-Output "NTFS Security module loaded"
}
Else {
	Install-Module "NTFSSecurity"
	Import-Module "NTFSSecurity"
    Write-Output "NTFS Security module loaded"
}

If (Get-Module -ListAvailable -Name "GetSTFolderSize") {
	Import-Module "GetSTFolderSize"
    Write-Output "GetSTFolderSize module loaded"
}
Else {
	Install-Module "GetSTFolderSize"
	Import-Module "GetSTFolderSize"
    Write-Output "GetSTFolderSize module loaded"
}

#SMTP Host, sending addresses, e-mail HTML formatting
$emailSmtpServer = "mail.domain.com"
$emailFrom = "no-reply@domain.com"
$emailToAddress = "user@domain.com"
#$emailCcAddress = "cc1@domain.com", "cc2@domain.com", "cc3@domain.com"
$emailTableStyle = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: #000000; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; color: #FFFFFF; background-color: #0000FF;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

#Program File Path
$DirPath = "C:\Scripts\Get-FileServerUsage"

#Check if program dir is present
$DirPathCheck = Test-Path -Path $DirPath
If (!($DirPathCheck)) {
    #If not present then create the dir
    New-Item -ItemType Directory $DirPath -Force
}

$todayDate = Get-Date

Write-Output "Getting directory info and outputting to file, run time is approximately 2 hours for this operation..."
$outDirsDataSet = @() #hashtable object to be filled later
$outDirsRDrive = Get-ChildItem -Path "\\server\folder\" -Directory | Sort-Object Name
ForEach ($folder in $outDirsRDrive) {
    $filesWritten = Get-ChildItem $folder.FullName -Recurse -Force
    If ($null -ne $filesWritten.LastWriteTime) {
        $activeFiles = ($filesWritten | Where-Object { (New-TimeSpan -Start $_.LastWriteTime -End $todayDate).Days -le 180 } | Measure-Object).Count
        Write-Output "$($folder.FullName) has $($activeFiles) files written in the last 180 days"
    } Elseif ($null -eq $filesWritten.LastWriteTime) {
        $activeFiles = $null
        Write-Output "$($folder.FullName) has $($activeFiles) never been written to"
    } Else {
        $activeFiles = $null
        Write-Output "Something donked up accessing $($folder.FullName)"
    }
    $getFolderInfo = Get-STFolderSize $folder.FullName -RoboOnly | Select-Object DirCount, FileCount, TotalGBytes
    #fill hashtable with this data
    $emailTableInputsFoldersProperties = @{
        "Folder"                         = $folder.FullName
        "Directory Count"                = $getFolderInfo.DirCount
        "File Count"                     = $getFolderInfo.FileCount
        "Size (in GB)"                   = $getFolderInfo.TotalGBytes
        "Files Written in Last 180 Days" = $activeFiles
    }
    $outDirsDataSet += New-Object PSObject -Property $emailTableInputsFoldersProperties
}

$csvDate = Get-Date -Format yyyyMMddTHHmmssffff
$outDirsDataSet | Sort-Object Path | Format-Table -Wrap -AutoSize | Out-File $DirPath\ShareDrive-DataSet-$csvDate.txt
$emailDataSet = $outDirsDataSet | Sort-Object Path | Format-Table -Wrap -AutoSize | ConvertTo-Html -Head $emailTableStyle
$emailSubjectUser = "Share Drive Data Set Report"
$emailBodyUser = @"
        <!DOCTYPE html>
        <html lang="en" dir="ltr">
        <head>
            <meta charset="utf-8">
            <title></title>
        </head>

        <body style="font-size: 14px; font-family: Tahoma;">
            Hello Service Desk Team,
            <br><br>
            These are the details of the share drive data set as of $Date`:
            <br><br>
            $emailDataSet
            <br>
            Column Descriptions:
            <ul>
                <li>Folder - The full path of the folder being scanned</li>
                <li>Directory Count - The amount of subdirectories in the top folder</li>
                <li>File Count - The amount of total files across the root directory and sub directory</li>
                <li>Size - The size of the entire folder in gigabytes</li>
                <li>Files Written in Last 180 Days - Total files written to the folder in the last 180 days</li>
                <li>Recommended action - Import text file into Google Sheets and tell it to not auto-convert fields</li>
                <li>Formatted text output is attached or can be found on $ENV:COMPUTERNAME at this path $DirPath\RDrive-DataSet-$csvDate.txt</li>
            </ul>
            <br><br>
            Thank you,
            <br>
            IT Ops Team
        </body>
        </html>
"@
Write-Output "Sending E-mail to $emailToaddress..."
Try {
    Send-MailMessage -To $emailToaddress -From $emailFrom -Subject $emailSubjectUser -Body $emailBodyUser -Attachments $DirPath\ShareDrive-DataSet-$csvDate.txt -SmtpServer $emailSmtpServer -Priority High -DeliveryNotificationOption OnSuccess, OnFailure -BodyAsHtml
} Catch {
    Write-Output "Unable to send e-mail"
}

$endTime = Get-Date
$endTime
Stop-Transcript