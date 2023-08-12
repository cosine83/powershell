#Turn off shares on old file server

$Server = Read-Host "Please enter old file server's name"
$DeptShare = Read-Host "Please enter the name of the old dept share"
$HomeShare = Read-Host "Please enter the name of the old home share"
$Shares = Get-SmbShare -CimSession $Server #| Where -Property Name -Filter { Name -like $DeptShare -or $HomeShare }

$Shares | Select Name | Where -Property Name -Filter { Name -like "SCCM" }
