<#
.PURPOSE

.LINKS

.TODO

.NOTES
Created By: Justin Grathwohl
Date Created:
Date Updated:

#>

$localUsers = Get-LocalUser

If($localUsers.Name -ccontains "Administrator") {
    Rename-LocalUser -Name "Administrator" -NewName "notAdmin"
    Write-Output "Local admin renamed"
} Else {
    Write-Output "Rename operation already done"
}