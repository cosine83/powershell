$getDisk = Get-CimInstance -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" } | Select-Object -Property DeviceID, VolumeName, @{Label = 'FreeSpace'; expression = { ($_.FreeSpace / 1GB).ToString('F2') } }, @{Label = 'TotalSize'; expression = { ($_.Size / 1GB).ToString('F2') } }, @{label = 'FreePercent'; expression = { [Math]::Round(($_.freespace / $_.size) * 100, 2) } }
#Sensor: os_disk_free_space
$getDisk.FreeSpace
#Sensor: os_disk_size
$getDisk.TotalSize
#Sensor: os_disk_free_percent
$getDisk.FreePercent