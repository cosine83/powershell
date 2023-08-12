#-----------------
#Define Variables
#-----------------
$Software = "VNC"
 
#-----------------
#Search software
#-----------------
$Product = Get-WmiObject -class SMS_InstalledSoftware -Namespace "root\cimv2\sms" | 
Where-Object {$PSItem.ProductName -like "*$Software*"}
 
#-----------------
#Uninstall software
#-----------------
 
    ForEach ($ObjItem in $Product) 
    {
 
    #-----------------
    #Define Variables
    #-----------------
    $ID = $ObjItem.SoftwareCode
    $SoftwareName = $ObjItem.ProductName
 
        #-----------------
        #Uninstall 
        #-----------------
        $Uninstall = "/x" + "$ID /qn" 
        $SP = (Start-Process -FilePath "msiexec.exe" $Uninstall -Wait -Passthru).ExitCode
 
    Write-Output "Uninstalled $SoftwareName"
    }
 
Write-Output "Done!"