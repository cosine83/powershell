#-----------------
#Define Variables
#-----------------
$Software = "VNC"
 
#-----------------
#Search software
#-----------------
Get-WmiObject -class SMS_InstalledSoftware -Namespace "root\cimv2\sms" | 
Where-Object {$PSItem.ProductName -like "*$Software*"}