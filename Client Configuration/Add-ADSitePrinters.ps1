<#
.PURPOSE
This script adds and removes the user's mapped printers based on their AD site. This can be detected at startup, logon, or periodically depending on how
this script is setup for usage - scheduled task, startup item via GPO, etc.

.LINKS

.TODO

.NOTES
Created By: Justin Grathwohl
Date Created: 04-21-2022
Date Updated: 11-09-2023

#>

#Logging and file transfer directories
$dirPath = "C:\Scripts\Add-ADSitePrinters"
$tempPath = "C:\temp"

#Check if logging directory is present
$dirPathCheck = Test-Path -Path $DirPath
$tempPathCheck = Test-Path -Path $tempPath

#Create logging directory if it doesn't exist
If (!($DirPathCheck)) {
    New-Item -ItemType Directory $DirPath -Force
}

If (!($tempPathCheck)) {
    New-Item -ItemType Directory $tempPath -Force
}

$csvDate = Get-Date -Format yyyyMMddTHHmmssffff
Start-Transcript -Path "$DirPath\Add-ADSitePrinters-$csvDate.txt"
function Get-ADComputerSite {
    param(
        [parameter(Mandatory=$false)]
        [string]$ComputerName = "$env:ComputerName"
    )
    ($site= nltest /server:$computername /dsgetsite) 2>&1> $null
    if ($lastexitcode -eq 0) {
        $site[0]
    }
}

$getADModule = Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}
If (!$getADModule){
    $compAdSite = Get-ADComputerSite
    $compAdSite | Out-File -FilePath $tempPath\ad_site.txt -Force
} Elseif ($getADModule){
    $getCompAdSite = Get-ADReplicationSite -Properties Name
    $compAdSite = $getCompAdSite.Name
    $compAdSite | Out-File -FilePath $tempPath\ad_site.txt -Force
}

$adSite = Get-Content C:\temp\ad_site.txt

Switch ($compAdSite) {
    "Site 1" { $printServer = Get-Printer -ComputerName "server1.domain.com" | Where-Object {$_.Name -notlike "*OLD" -and $_.Name -notlike "*Zebra*" -and $_.Published -eq $true} }
    "Site 2" { $printServer = Get-Printer -ComputerName "server2.domain.com" | Where-Object {$_.Name -notlike "*OLD" -and $_.Name -notlike "*Zebra*" -and $_.Published -eq $true} }
    "Site 3" { $printServer = Get-Printer -ComputerName "server3.domain.com" | Where-Object {$_.Name -notlike "*OLD" -and $_.Name -notlike "*Zebra*" -and $_.Published -eq $true} }
    "Site 4" { $printServer = Get-Printer -ComputerName "server4.domain.com" | Where-Object {$_.Name -notlike "*OLD" -and $_.Name -notlike "*Zebra*" -and $_.Published -eq $true} }
}

If ($adSite -notmatch $compAdSite) {
    Write-Output "AD site mismatch, removing all mapped printers..."
    Get-Printer | Where-Object {$_.Type -eq "Connection"} | Remove-Printer
} Elseif ($adSite -match $compAdSite) {
    Write-Output "AD sites match, removing any non-local campus printers..."
    Switch ($compAdSite.Name) {
        "Site 1" { $getNonLocalPrinters = Get-Printer | Where-Object {$_.Type -eq "Connection" -and $_.ComputerName -notlike "server1*" -and $_.Name -notlike "*Zebra*"} }
        "Site 2" { $getNonLocalPrinters = Get-Printer | Where-Object {$_.Type -eq "Connection" -and $_.ComputerName -notlike "server2*" -and $_.Name -notlike "*Zebra*"} }
        "Site 3" { $getNonLocalPrinters = Get-Printer | Where-Object {$_.Type -eq "Connection" -and $_.ComputerName -notlike "server3*" -and $_.Name -notlike "*Zebra*"} }
        "Site 4" { $getNonLocalPrinters = Get-Printer | Where-Object {$_.Type -eq "Connection" -and $_.ComputerName -notlike "server4*" -and $_.Name -notlike "*Zebra*"} }
    }
    Write-Output "Unmapped`: $($getNonLocalPrinters.Name)"
    $getNonLocalPrinters | Remove-Printer
}

Write-Output "Adding any unmapped local campus printers"
ForEach ($netPrinter in $printServer) {
    $printer = $netPrinter.Name
    $printerServer = $netPrinter.ComputerName
    $getLocalPrinter = Get-Printer \\$($printerServer)\$($printer) -ErrorAction SilentlyContinue
    If (!$getLocalPrinter) {
        Write-Output "Mapping $($printer)"
        Add-Printer -ConnectionName \\$($printerServer)\$($printer)
    } Else {
        Write-Output "$($printer) already mapped"
    }
}
Stop-Transcript