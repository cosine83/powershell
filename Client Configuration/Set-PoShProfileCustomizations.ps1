<#
.PURPOSE
Script to setup my PowerShell cusotmizations on new machines.

.LINKS

.TODO

.NOTES
Created By: Justin Grathwohl
Date Created:
Date Updated:

#>

winget install JanDeDobbeleer.OhMyPosh -s winget
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/night-owl.omp.json" | Invoke-Expression
. $PROFILE