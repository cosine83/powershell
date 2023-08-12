#Deploy hotfixes to Windows

$HotfixPath = "\\server\share\Hotfixes"
$Win7Files = Get-ChildItem -Path $HotfixPath | where {$_.Name -like "Windows6.1*"}
$Win8Files = Get-ChildItem -Path $HotfixPath | where {$_.Name -like "Windows8.1*"}
$Win7Query = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystemVersion -like "6.1*"} -Properties * | Sort Name # This applies to Windows 7 and Server 2008 R2
$Win8Query = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystemVersion -like "6.3*"} -Properties * | Sort Name # This applies to Windows 8.1 and Server 2012 R2
$Win7Computers = $Win7Query.Name
$Win8Computers = $Win8Query.Name

foreach ($computer in $Win7Computers) {
	if (Test-Connection $computer -Count 1 -Quiet) {
		foreach ($File in $Win7Files) {
			Invoke-Command -ComputerName $computer -ScriptBlock {
				wusa.exe "$using:HotfixPath\$using:File" /quiet /norestart
			}
		}
		Write-Host "All hotfixes installed on $computer"
	}
	else {
		Write-Host "Can't connect to $computer"
	}
}

foreach ($computer in $Win8Computers) {
	if (Test-Connection $computer -Count 1 -Quiet) {
		foreach ($File in $Win8Files) {
			Invoke-Command -ComputerName $computer -ScriptBlock {
				wusa.exe "$using:HotfixPath\$using:File" /quiet /norestart
			}
		}
		Write-Host "All hotfixes installed on $computer"
	}
	else {
		Write-Host "Can't connect to $computer"
	}
}
