#Time sync scheduled task

$computers = Get-ADGroupMember "Servers" | Select Name | Sort Name
$TimeType = Get-ItemProperty -Path HKLM:\System\CurrentControlSet\Services\W32Time\Parameters | Select -ExpandProperty Type

ForEach ($computer in $computers){
	Invoke-Command -ComputerName $computer -ScriptBlock {
		If ($using:TimeType -ne "NT5DS") { 
			w32tm /config /syncfromflags:domhier /update #| Out-Null
			net stop w32time #| Out-Null
			net start w32time #| Out-Null
			w32tm /resync #| Out-Null
			net time /set /y #| Out-Null
		}
		Else {
			w32tm /resync #| Out-Null
			net time /set /y #| Out-Null
		}
	}
}
