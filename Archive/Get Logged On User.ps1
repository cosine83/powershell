$computer = Read-Host "What computer do you want to get the current logged on user?"

Get-WMIObject -class Win32_ComputerSystem -ComputerName $computer | select username