<#
.PURPOSE
The purpose of this script is to cleanup bad/invalid activation via reinstalling the license and activating.

.LINKS

.TODO

.NOTES
Created By: Justin Grathwohl
Date Created:
Date Updated:

#>

$key = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object { $_.PartialProductKey -ne $null } | Select-Object Description, LicenseStatus, PartialProductKey
If ($key.PartialProductKey -ne "XXXXX" -and $key.Description -like "*MAK*") {
    slmgr.vbs //B -rilc
    slmgr.vbs //B -upk
    slmgr.vbs //B -ipk W269N-WFGWX-YVC9B-4J6C9-T83GX #Windows 11 Pro GVLK
    slmgr.vbs //B -ato
    Write-Output "License key activated"
} Else {
    Write-Output "Reimage"
    return 0
}