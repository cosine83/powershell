Import-Module activedirectory

$searchbase = "OU=Secondary,OU=Primary,DC=domain,DC=com"

$query = Get-ADComputer -Filter * -SearchBase $searchbase | Select Name | Sort Name
$computers = $query.Name

foreach ($computer in $computers)
{
    Write-Host "Connecting..."
	If(Test-Connection $computer -Count 1 -Quiet) #Check that PC is online
    {
        Write-Host "$computer - Changing Windows 7 License Key!"
		$WinKey = 'Insert Key Here'
		$service = get-wmiObject -query "select * from SoftwareLicensingService" -ComputerName $computer
		$service.InstallProductKey($WinKey)
		$service.RefreshLicenseStatus()
		Write-Host -ForegroundColor Green "$computer - Windows 7 License Key updated!"
	}
	else
    {
        #PC was offline
        Write-Host -ForegroundColor Red "$computer - Offline!"
    }#End out If/Else
}#End foreach loop