#Remove disabled AD computers from SCCM
#This requires having the SCCM Powershell mdoule and cmdlets installed on the computer you're running the script

#Load VB-based dialog window
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

#Import ConfigMgr module and set directory to site code so the script will actually work
Import-Module ConfigurationManager
$WorkDir = Get-Location
$SiteCode = [Microsoft.VisualBasic.Interaction]::InputBox("What's the SCCM Site Code?", "Site Code")
Set-Location $SiteCode`:

$computers = get-adcomputer -filter {Enabled -eq $false} | Sort Name
$name = $computers.Name

foreach ($computer in $name) {
	if((Get-CMDevice -Name $computer)) {
		Remove-CMDevice -DeviceName $computer -Force -Confirm:$false
		Write-Output " $computer removed from SCCM database"
	}
	else {
		Write-Output "$computer not in SCCM database"
	}
}

Set-Location $WorkDir