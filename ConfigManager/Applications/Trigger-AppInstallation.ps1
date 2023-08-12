Function Trigger-AppInstallation
{
 
Param
(
 [String][Parameter(Mandatory=$True, Position=1)] $Computername,
 [String][Parameter(Mandatory=$True, Position=2)] $AppName,
 [ValidateSet("Install","Uninstall")]
 [String][Parameter(Mandatory=$True, Position=3)] $Method
)
 
Begin {
$Application = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Computername | Where-Object {$_.Name -like $AppName})
 
$Args = @{EnforcePreference = [UINT32] 0
Id = "$($Application.id)"
IsMachineTarget = $Application.IsMachineTarget
IsRebootIfNeeded = $False
Priority = 'High'
Revision = "$($Application.Revision)" }
 
}
 
Process
 
{
 
Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -ComputerName $Computername -MethodName $Method -Arguments $Args
 
}
 
End {}
 
}