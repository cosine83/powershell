$computer = Read-Host "Enter the name of the computer you want to reset group policy on"

If(Test-Connection $computer -Count 1 -Quiet) {
	If(Test-WSMan $computer) {
		Invoke-Command -ComputerName $computer -ScriptBlock {
			Remove-Item -Recurse -Path 'HKLM:\Software\Policies\Microsoft' -Force
			Remove-Item -Recurse -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Group Policy' -Force
			Remove-Item -Recurse -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects' -Force
			Remove-Item -Recurse -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects' -Force
			Remove-Item -Recurse -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Group Policy' -Force
			Remove-Item -Recurse -Path 'HKCU:\Software\Policies\Microsoft' -Force
			Remove-Item -Recurse -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies' -Force
			Remove-Item -Recurse -Path 'C:\Windows\System32\GroupPolicy' -Force
			Remove-Item -Recurse -Path 'C:\Windows\System32\GroupPolicyUsers' -Force
			Remove-Item -Recurse -Path 'C:\Users\*\AppData\Local\Group Policy' -Force
			Remove-Item -Recurse -Path 'C:\ProgramData\GroupPolicy' -Force
		}
		Write-Host "Group Policy reset, beginning refresh"
		Invoke-GPUpdate -Computer $computer -Force -RandomDelayInMinutes 0 -LogOff -Boot | Out-Null
		Write-Host "Group policy refreshed, please notify the user`(s`) and reboot the computer"
	}
	else {
		Write-Host "WinRM is unavailable, please enable"
	}
}
else {
	Write-Host -ForegroundColor Red "Can't connect to $computer"
}
