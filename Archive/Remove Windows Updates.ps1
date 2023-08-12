#Remove Windows Updates

#Load VB-based dialog window
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

$ErrorActionPreference = "SilentlyContinue"

$HotfixID = [Microsoft.VisualBasic.Interaction]::InputBox("What is the KB number of the update to remove?", "Update KB Number")
$query = Get-ADComputer -Filter {Enabled -eq $true} | Sort Name
$computers = $query.Name

foreach ($computer in $computers) { 
	if(Test-Connection $computer -Count 1 -Quiet) {
		$GetOSVer = (Get-WMIObject -ComputerName $computer -class Win32_OperatingSystem).Version
		$Hotfix = Get-Hotfix -Id KB$HotfixID -ComputerName $computer
		if ($Hotfix) {
			Write-Host -Foreground Yellow -Background Black "Removing hotfix KB$HotfixID on $computer"
			if ($GetOSVer -like "5.1*" -or $GetOSVer -like "5.2*") {
				Invoke-Command -ComputerName $computer -ScriptBlock {
					C:\Windows\`$NtUninstallKB$using:HotfixID`$\spuninst\spuninst.exe /quiet /norestart
				}
			}
			else {
				Invoke-Command -ComputerName $computer -ScriptBlock {
					cmd.exe /c wusa.exe /uninstall /kb:$using:HotfixID /quiet /norestart
				}
			}
		}
		else {
			Write-Host -Foreground Yellow -Background Black "Hotfix not installed on $computer"
		}
	}
	else {
		Write-Host -Foreground Yellow -Background Black "Can't ping $computer"
	}
}
