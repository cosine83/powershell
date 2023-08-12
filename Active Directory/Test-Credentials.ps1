<#
.PURPOSE
The purpose of this script is to allow one to enter a set of AD credentials to test if they're currently valid.

.LINKS

.TODO
- Add ability to have exceptions at runtime without predefining in the script

.NOTES
Created By: Justin Grathwohl
Date Created:
Date Updated:

#>

$cred = Get-Credential #Read credentials
$username = $cred.username
$password = $cred.GetNetworkCredential().password

# Get current domain using logged-on user's credentials
$CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
$domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain, $UserName, $Password)

if ($null -eq $domain.name) {
    Write-Host "Authentication failed - please verify your username and password."
    exit #terminate the script.
} else {
    Write-Host "Successfully authenticated with domain $domain.name"
}

