$getIPAddress = Get-NetIPAddress | Where-Object { $_.IPAddress -like "10.*" } | Select-Object InterfaceAlias, IPAddress
$getIPAddress.IPAddress