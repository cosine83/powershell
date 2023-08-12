<#
.Synopsis
Monolithic script for AD cleanup
- Disables and moves users and computers inactive for 90 or more days to the proper OUs
- Moves already disabled users and computers to their proper OUs if not there
- Moves empty groups
- Removes empty groups
- Removes disabled users and computers from groups
- Deletes objects 180 days or older
- CSV and e-mail output for logging and compliance for moved, disabled, and removed items

.DESCRIPTION


.NOTES
Name: Cleanup-StaleADObjectsDryRun.ps1
Author: Justin Grathwohl
Version: 2.0
DateUpdated:2023-01-18

.TODO
Fix and cleanup group filtering for domain users and built-in groups
Account for null logon dates via if statements
E-mail and CSV for users with null logon dates
#>

#Date formatting for logging outputs and queries
$Date = Get-Date -Format MM/dd/yyyy
$todayDate = Get-Date
$csvDate = Get-Date -Format yyyyMMddTHHmmssffff

Start-Transcript -Path "$DirPath\Cleanup-StaleAdObjectsDryRun-$csvDate.txt"

Write-Output "Loading required modules"
Import-Module ActiveDirectory

#SMTP Host, addresses, formatting, and e-mail inputs
$emailSmtpServer = "smtp.domain.com"
$emailFrom = "no-reply@domain.com"
$emailToAddress = "main.recipient@domain.com"
$emailCcAddress = "cc1@domain.com", "cc2@domain.com", "cc3@domain.com"
$emailTableUsers = @()
$emailTableComps = @()
$emailTableGroups = @()
$emailTableStyle = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: #000000; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #0000FF;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

#Logging directory
$DirPath = "C:\Scripts\Cleanup-StaleAdObjects"

#Check if logging directory is present
$DirPathCheck = Test-Path -Path $DirPath

#Create logging directory if it doesn't exist
If (!($DirPathCheck)) {
    New-Item -ItemType Directory $DirPath -Force
}

#OUs for AD queries to keep the scope of execution limited
$inactiveCompsOU = "OU=ComputersToDelete,OU=Objects To Delete,OU=Organization,dc=domain,dc=com"
$retiredUsersOU = "OU=Retired,OU=Accounts,OU=Organization,dc=domain,dc=com"
$emptyGroupsOU = "OU=GroupsToDelete,OU=Objects To Delete,OU=Organization,dc=domain,dc=com"
$accountsOU = "OU=Accounts,OU=Organization,dc=domain,dc=com"
$systemsOU = "OU=Systems,OU=Organization,dc=domain,dc=com"

Write-Output "Before starting, please answer the following questions with yes or no to determine script actions"
$disableMoveComputers = Read-Host "Disable and move computers that have been inactive 90+ days?"
$disableMoveUsers = Read-Host "Disable and move users who have been inactive 90+ days?"
$moveDisabledComputers = Read-Host "Move already disabled computers?"
$moveDisabledUsers = Read-Host "Move already disabled users?"
$removeCompFromGroups = Read-Host "Remove disabled computers from non-default groups?"
$removeUserFromGroups = Read-Host "Remove disabled users from non-default groups?"
$moveEmptyGroups = Read-Host "Would you like to move non-built-in empty groups?"
$cleanEmptyGroups = Read-Host "Would you like to remove non-built-in empty groups?"
$cleanRetiredComps = Read-Host "Would you like to remove all disabled computers in the retired OU?"
$cleanRetiredUsers = Read-Host "Would you like to remove all disabled users in the retired OU?"

#Enabled but inactive user and computer AD search looking for 90+ days inactivity
#Filters out null logon users, servers, and service accounts
$compLogon = Search-ADAccount -AccountInactive -DateTime ((Get-Date).adddays(-90)) -ComputersOnly -ResultPageSize 1000 -SearchBase $systemsOU | Where-Object { $_.DistinguishedName -notlike "*Servers*" -and $_.LastLogonDate -ne "12/31/1600 4:00:00 PM" -and $_.LastLogonDate -ne $null } | Select-Object Name, DistinguishedName, ObjectGUID, LastLogonDate | Sort-Object Name
$userLogon = Search-ADAccount -AccountInactive -DateTime ((Get-Date).adddays(-90)) -UsersOnly -ResultPageSize 1000 -SearchBase $accountsOU | Where-Object { $_.DistinguishedName -notlike "*OU=Service Accounts*" -and $_.LastLogonDate -ne "12/31/1600 4:00:00 PM" -and $_.LastLogonDate -ne $null } | Select-Object Name, DistinguishedName, ObjectGUID, LastLogonDate, SamAccountName | Sort-Object Name

Write-Output "All CSV outputs can be found in $DirPath"
If ($disableMoveComputers -eq "yes" -or $disableMoveComputers -eq "y") {
    Write-Output "Beginning search for inactive computers that need to be disabled and moved"
    ForEach ($computer in $compLogon) {
        $compQuery = Get-ADComputer $computer.DistinguishedName -Properties OperatingSystem, LastLogonDate
        $pingComp = Test-Connection $compQuery.Name -Count 1 -Quiet
        #Tests ping and WMI response before doing operations, if offline disable and move; if online, note in a CSV and move on with no action.
        If ($pingComp -eq $false) {
            #Builds readable hashtable for CSV output
            $emailTableInputsCompsProperties = [ordered]@{
                "Name"       = ($compQuery).name
                "OS"         = ($compQuery).OperatingSystem
                "Last Logon" = $computer.LastLogonDate
                "Action"     = "Disabled and moved"
            }
            $emailTableComps += New-Object psobject -Property $emailTableInputsCompsProperties
            Write-Output "$($computer).Name disabled and moved, last logon noted in description field"
            #Dump the computer info to a CSV that's appended on each loop
            $compQuery | Select-Object Name, Enabled, DistinguishedName | Export-Csv -NoTypeInformation -Append -Path "$DirPath\Disabled-Computers-$csvDate.csv"
            #Cmdlets that do the work of disabling, setting a description with the last logon date, disables deletion protection, then moves it to the to be deleted OU.
            Set-ADComputer -Identity $computer.ObjectGUID -Description "Last logon $computer.LastLogonDate" -WhatIf
            Set-ADComputer -Identity $computer.ObjectGUID -Enabled $false -WhatIf
            Set-ADObject -Identity $computer.ObjectGUID -ProtectedFromAccidentalDeletion:$false -PassThru -WhatIf
            Move-ADObject -Identity $computer.ObjectGUID -TargetPath $inactiveCompsOU -WhatIf
        } Else {
            #Appends pingable but "inactive" computers to CSV with no modifications to the account
            Write-Output "$computer.Name pings but may need a reboot or domain re-join due to last reported domain logon"
            $compQuery | Select-Object Name, Enabled, DistinguishedName | Export-Csv -NoTypeInformation -Append -Path "$DirPath\Inactive-Pingable-Computers-$csvDate.csv"
        }
    }
} Else {
    Write-Output "Opted not to disable and move 90+ day inactive computers."
}

If ($disableMoveUsers -eq "yes" -or $disableMoveUsers -eq "y") {
    Write-Output "Beginning search for inactive users that need to be disabled and moved"
    ForEach ($user in $userLogon) {
        $userQuery = Get-ADUser $user.DistinguishedName -Properties LastLogonDate
        $emailTableInputsUsersProperties = [ordered]@{
            "User"       = ($userQuery).name
            "Username"   = ($userQuery).SamAccountName
            "Last Logon" = $user.LastLogonDate
            "Action "    = "Disabled and moved"
        }
        $emailTableUsers += New-Object psobject -Property $emailTableInputsUsersProperties
        Write-Output "$user.DisplayName disabled and moved"
        $userQuery | Select-Object Name, SamAccountName, LastLogonDate, DistinguishedName | Export-Csv -NoTypeInformation -Append -Path "$DirPath\Disabled-Users-$csvDate.csv"
        Set-ADUser -Identity $user.ObjectGUID -Description "Last logon $user.LastLogonDate" -WhatIf
        Set-ADUser -Identity $user.ObjectGUID -Enabled $false -WhatIf
        Set-ADObject -Identity $user.ObjectGUID -ProtectedFromAccidentalDeletion:$false -PassThru -WhatIf
        Move-ADObject -Identity $user.ObjectGUID -TargetPath $retiredUsersOU -WhatIf
    }
} Else {
    Write-Output "Opted not to disable and move 90+ day inactive users."
}

$disUsers = Search-ADAccount -AccountDisabled -UsersOnly -ResultPageSize 1000 -SearchBase $accountsOU | Where-Object-Object { $_.DistinguishedName -notlike "*OU=Service Accounts*" -and $_.DistinguishedName -notlike "*OU=Retired*" }
$disComps = Search-ADAccount -AccountDisabled -ComputersOnly -ResultPageSize 1000 -SearchBase $systemsOU

If($moveDisabledComputers -eq "yes" -or $moveDisabledComputers -eq "y") {
    Write-Output "Looking for already disabled computers and moving them to the retired OU"
    ForEach ($computer in $disComps) {
        $compQuery = Get-ADComputer $computer.DistinguishedName -Properties OperatingSystem, LastLogonDate
        $emailTableInputsCompsProperties = [ordered]@{
            "Name"       = ($compQuery).name
            "OS"         = ($compQuery).OperatingSystem
            "Last Logon" = $computer.LastLogonDate
            "Action"     = "Moved, already disabled"
        }
        $emailTableComps += New-Object psobject -Property $emailTableInputsCompsProperties
        Write-Output "$computer.Name was already disabled, moved to the retired OU and noted the last logon in the description field"
        $compQuery | Select-Object Name, Enabled, DistinguishedName | Export-Csv -NoTypeInformation -Append -Path "$DirPath\Disabled-Computers-$csvDate.csv"
        Move-ADObject -Identity $computer.ObjectGUID -TargetPath $inactiveCompsOU -WhatIf
    }
} Else {
    Write-Output "Opted not to move currently disabled computers not in the retired computer OU."
}

If($moveDisabledUsers -eq "yes" -or $moveDisabledUsers -eq "y") {
    ForEach ($user in $disUsers) {
        $userQuery = Get-ADUser $user.DistinguishedName -Properties LastLogonDate
        $emailTableInputsUsersProperties = [ordered]@{
            "User"       = ($userQuery).name
            "Username"   = ($userQuery).SamAccountName
            "Last Logon" = $user.LastLogonDate
            "Action"     = "Moved, already disabled"
        }
        $emailTableUsers += New-Object psobject -Property $emailTableInputsUsersProperties
        Write-Output "$user.DisplayName was already disabled, moved to retired OU"
        $userQuery | Select-Object Name, SamAccountName, LastLogonDate, DistinguishedName | Export-Csv -NoTypeInformation -Append -Path "$DirPath\Disabled-Users-$csvDate.csv"
        Move-ADObject -Identity $user.ObjectGUID -TargetPath $retiredUsersOU -WhatIf
    }
} Else {
    Write-Output "Opted not to move currently disabled users not in the retired users OU."
}

If($removeCompFromGroups -eq "yes" -or $removeCompsFromGroups -eq "y") {
    $gQuery = Get-ADGroup -Filter { Name -notlike "Domain*" } -ResultPageSize 1000
    $dComps = Search-ADAccount -AccountDisabled -ComputersOnly -SearchBase $inactiveCompsOU -ResultPageSize 1000
    ForEach ($comp in $dComps) {
        $csvCompQuery = $comp | Select-Object Name, @{N = "Last Logon"; E = "LastLogonDate" }
        $csvCompQuery | Export-Csv -NoTypeInformation -Append $DirPath\Removed-ComputerAccountsGroups-$csvDate.csv -Force
    }
    Write-Output "Removing disabled computers from groups."
    ForEach ($group in $gQuery) {
        Remove-ADGroupMember -Identity $group -Member $dComps -Confirm:$false -WhatIf
    }
}

If($removeUserFromGroups -eq "yes" -or $removeUserFromGroups -eq "y") {
    $gQuery = Get-ADGroup -Filter { Name -notlike "Domain*" } -ResultPageSize 1000
    $dUsers = Search-ADAccount -AccountDisabled -UsersOnly -SearchBase $retiredUsersOU -ResultPageSize 1000
    ForEach ($user in $dUsers) {
        $csvUserQuery = $user | Select-Object Name, @{N = "User Name"; E = "SamAccountName" }, @{N = "Last Logon"; E = "LastLogonDate" }
        $csvUserQuery | Export-Csv -NoTypeInformation -Append $DirPath\Removed-UserAccountsGroups-$csvDate.csv -Force
    }
    Write-Output "Removing disabled users from groups."
    ForEach ($group in $gQuery) {
        Remove-ADGroupMember -Identity $group -Member $dUsers -Confirm:$false -WhatIf
    }
}

If ($moveEmptyGroups -eq "yes" -or $moveEmptyGroups -eq "y") {
    Write-Output "Moving empty groups..."
    $emptyGroupsQuery = Get-ADGroup -Filter * | Where-Object { $_.DistinguishedName -notlike "*OU=GroupsToDelete,*" }
    ForEach ($group in $emptyGroupsQuery) {
        $memberCount = (Get-ADGroupMember $group | Measure-Object).Count
        If ($memberCount -eq 0) {
            Set-ADObject -Identity $group.ObjectGUID -ProtectedFromAccidentalDeletion:$false -PassThru -WhatIf
            Move-ADObject -Identity $group.ObjectGUID -TargetPath $emptyGroupsOU -WhatIf
            $emailTableInputsGroupsProperties = [ordered]@{
                "Group"  = $group.name
                "Action" = "Moved, no members"
            }
            $emailTableGroups += New-Object psobject -Property $emailTableInputsGroupsProperties
            $group | Select-Object Name, DistinguishedName | Export-Csv -NoTypeInformation -Append -Path "$DirPath\Moved-Groups-$csvDate.csv"
        }
    }
}

If ($cleanEmptyGroups -eq "yes" -or $cleanEmptyGroups -eq "y") {
    Write-Output "Checking empty groups and removing..."
    $emptyGroups = Get-ADGroup -Filter * -SearchBase $emptyGroupsOU
    ForEach ($group in $emptyGroups) {
        $memberCount = (Get-ADGroupMember $group | Measure-Object).Count
        If ($memberCount -eq 0) {
            Write-Output $group.Name "does not contain any members, removing..."
            $emailTableInputsGroupsProperties = [ordered]@{
                "Group"  = $group.name
                "Action" = "Removed, no members"
            }
            $emailTableGroups += New-Object psobject -Property $emailTableInputsGroupsProperties
            $group | Select-Object Name, DistinguishedName | Export-Csv -NoTypeInformation -Append -Path "$DirPath\Removed-Groups-$csvDate.csv"
            Remove-ADGroup $group -Confirm:$false -WhatIf
        } Else {
            Write-Output $group.Name "contains members, move it back to its respective OU"
        }
    }
}

$rcompLogon = Search-ADAccount -AccountDisabled -ComputersOnly -SearchBase $inactiveCompsOU -ResultPageSize 1000 | Where-Object { (New-TimeSpan -Start $_.LastLogonDate -End $todayDate).Days -ge 180 -and $_.LastLogonDate -ne $null } | Select-Object Name, DistinguishedName, ObjectGUID, LastLogonDate, OperatingSystem | Sort-Object Name
$ruserLogon = Search-ADAccount -AccountDisabled -UsersOnly -SearchBase $retiredUsersOU -ResultPageSize 1000 | Where-Object { (New-TimeSpan -Start $_.LastLogonDate -End $todayDate).Days -ge 180 -and $_.LastLogonDate -ne $null } | Select-Object DisplayName, DistinguishedName, ObjectGUID, LastLogonDate |  Sort-Object DisplayName

If ($cleanRetiredComps -eq "yes" -or $cleanRetiredComps -eq "y") {
    ForEach ($rcomputer in $rcompLogon) {
        $rcompQuery = Get-ADComputer $rcomputer.DistinguishedName -Properties OperatingSystem, LastLogonDate
        $emailTableInputsCompsProperties = [ordered]@{
            "Name"       = ($rcompQuery).Name
            "OS"         = ($rcompQuery).OperatingSystem
            "Last Logon" = $rcomputer.LastLogonDate
            "Action"     = "Removed"
        }
        $emailTableComps += New-Object psobject -Property $emailTableInputsCompsProperties
        $rcompQuery | Select-Object Name, LastLogonDate, DistinguishedName | Export-Csv -NoTypeInformation -Append -Path "$DirPath\Removed-Computers-$csvDate.csv"
        Remove-ADObject -Identity $rcomputer.ObjectGUID -Recursive -Confirm:$false -WhatIf
    }
}

If ($cleanRetiredUsers -eq "yes" -or $cleanRetiredUsers -eq "y") {
    ForEach ($ruser in $ruserLogon) {
        $ruserQuery = Get-ADUser $ruser.DistinguishedName -Properties LastLogonDate
        $emailTableInputsUsersProperties = [ordered]@{
            "User"       = ($ruserQuery).Name
            "Username"   = ($ruserQuery).SamAccountName
            "Last Logon" = $ruser.LastLogonDate
            "Action"     = "Removed"
        }
        $emailTableUsers += New-Object psobject -Property $emailTableInputsUsersProperties
        $ruserQuery | Select-Object Name, SamAccountName, LastLogonDate, DistinguishedName | Sort-Object Name | Export-Csv -NoTypeInformation -Append -Path "$DirPath\Removed-Users-$csvDate.csv"
        Remove-ADObject -Identity $ruser.ObjectGUID -Recursive -Confirm:$false -WhatIf
    }
}

#Creates the HTML tables from the hashtables built in previous actions 
$emailRemovedUsers = $emailTableUsers | Select-Object User, Username, LastLogonDate, Action | ConvertTo-Html -Head $emailTableStyle
$emailRemovedComps = $emailTableComps | Select-Object Name, OS, Action |  ConvertTo-Html -Head $emailTableStyle
$emailAttachments = Get-ChildItem -Path $DirPath -Filter *.csv | Where-Object { $_.LastWriteTime -like "$todayDate" }

#Sends emails using the HTML formatted tables for the email body. Sends whether there's numebrs to report or not so there's no questions on status.
#All removed users and computers are appended to a CSV output to keep track of what's been done.
If (($ruserLogon).Count -lt 1 -and ($rcompLogon).Count -lt 1) {
    $emailSubject = "(Dry Run) No Users or computers disabled or removed"
    $emailBody = @"
    <!DOCTYPE html>
    <html lang="en" dir="ltr">
    <head>
        <meta charset="utf-8">
        <title></title>
    </head>

    <body style="font-size: 14px; font-family: Tahoma;">
        Hello Service Desk Team,
        <br><br>
        There are currently no users or compupters to disable or remove as of $Date. If you'd like to double check, please contact Justin or Nico.
        If there are no inactive accounts:
        <ul>
            <li>Assign ticket to Service Desk Manager</li>
            <li>Note that there are no stale AD objects to remove</li>
            <li>Service Desk Manager will advise on whether to verify output or close the ticket</li>
        </ul>
        <br><br>
        Thank you,
        <br>
        IT Ops Team
    </body>
    </html>
"@

    Write-Output "Sending E-mail to $emailaddress..."
    Try {
        Send-MailMessage -To $emailToAddress -Cc $emailCcAddress -From $emailFrom -Subject $emailSubject -Body $emailBody -SmtpServer $emailSmtpServer -Priority High -DeliveryNotificationOption OnSuccess, OnFailure -BodyAsHtml -Attachments $emailAttachments
    } Catch {
        Write-Output "Unable to send e-mail"
    }
} Elseif (($ruserLogon).Count -ge 1 -and ($rcompLogon).Count -ge 1) {
    ForEach ($ruser in $ruserLogon) {
        $csvUserQuery = $ruser | Select-Object Name, @{N = "User Name"; E = "SamAccountName" }, @{N = "Last Logon"; E = "LastLogonDate" }, @{N = "AD Location"; E = "DistinguishedName" }
        $csvUserQuery | Export-Csv -NoTypeInformation -Append $DirPath\Removed-UserAccounts.csv -Force
    }
    ForEach ($rcomp in $rcompLogon) {
        $csvCompQuery = $rcomp | Select-Object Name, @{N = "Last Logon"; E = "LastLogonDate" }, @{N = "AD Location"; E = "DistinguishedName" }
        $csvCompQuery | Export-Csv -NoTypeInformation -Append $DirPath\Removed-ComputerAccounts.csv -Force
    }

    $emailSubjectUser = "(Dry Run) Disabled or Removed Users"
    $emailBodyUser = @"
    <!DOCTYPE html>
    <html lang="en" dir="ltr">
    <head>
        <meta charset="utf-8">
        <title></title>
    </head>

    <body style="font-size: 14px; font-family: Tahoma;">
        Hello Service Desk Team,
        <br><br>
        These are the user accounts that were disabled or removed in Active Directory as of $Date please verify they are still active:
        <br><br>
        $emailRemovedUsers
        <br>
        If these accounts are inactive please perform the following:
        <ul>
            <li>Assign ticket to Service Desk Manager</li>
            <li>Note that the user is inactive</li>
            <li>Verify list with Service Desk Manager</li>
            <li>Move the account to "domain.com/Organization/Accounts/Retired/"</li>
            <li>Service Desk Manager will advise on what to add to the description field</li>
        </ul>
        <br>
        If these accounts are active please contact the user and assist them connecting to the domain.
        <br><br>
        Thank you,
        <br>
        IT Ops Team
    </body>
    </html>
"@

    Write-Output "Sending E-mail to $emailaddress..."
    Try {
        Send-MailMessage -To $emailToaddress -Cc $emailCcAddress -From $emailFrom -Subject $emailSubjectUser -Body $emailBodyUser -SmtpServer $emailSmtpServer -Priority High -DeliveryNotificationOption OnSuccess, OnFailure -BodyAsHtml -Attachments $emailAttachments
    } Catch {
        Write-Output "Unable to send e-mail"
    }

    $emailSubjectComp = "(Dry Run) Disabled or Removed Computers"
    $emailBodyComp = @"
    <!DOCTYPE html>
    <html lang="en" dir="ltr">
    <head>
        <meta charset="utf-8">
        <title></title>
    </head>

    <body style="font-size: 14px; font-family: Tahoma;">
        Hello Service Desk Team,
        <br><br>
        These are the computers that were disabled or removed from Active Directory as of $Date please verify they are still active:
        <br><br>
        $emailRemovedComps
        <br>
        If these accounts are inactive please perform the following:
        <ul>
            <li>Assign ticket to Service Desk Manager</li>
            <li>Note that the user is inactive</li>
            <li>Verify list with Service Desk Manager</li>
            <li>Move the account to "domain.com/Organization/Accounts/Retired/"</li>
            <li>Service Desk Manager will advise on what to add to the description field</li>
        </ul>
        <br>
        If these accounts are active please contact the user and assist them connecting to the domain.
        <br><br>
        Thank you,
        <br>
        IT Ops Team
    </body>
    </html>
"@

    Write-Output "Sending E-mail to $emailaddress..."
    Try {
        Send-MailMessage -To $emailToaddress -Cc $emailCcAddress -From $emailFrom -Subject $emailSubjectComp -Body $emailBodyComp -SmtpServer $emailSmtpServer -Priority High -DeliveryNotificationOption OnSuccess, OnFailure -BodyAsHtml -Attachments $emailAttachments
    } Catch {
        Write-Output "Unable to send e-mail"
    }
} Elseif (($ruserLogon).Count -lt 1 -and ($rcompLogon).Count -ge 1) {
    ForEach ($rcomp in $rcompLogon) {
        $csvCompQuery = $rcomp | Select-Object Name, @{N = "Last Logon"; E = "LastLogonDate" }, @{N = "AD Location"; E = "DistinguishedName" }
        $csvCompQuery | Export-Csv -NoTypeInformation -Append $DirPath\Removed-ComputerAccounts.csv -Force
    }

    $emailSubjectComp = "(Dry Run) Disabled or Removed Computers"
    $emailBodyComp = @"
    <!DOCTYPE html>
    <html lang="en" dir="ltr">
    <head>
        <meta charset="utf-8">
        <title></title>
    </head>

    <body style="font-size: 14px; font-family: Tahoma;">
        Hello Service Desk Team,
        <br><br>
        These are the computers that were disabled or removed from Active Directory as of $Date please verify they are still active:
        <br><br>
        $emailRemovedComps
        <br>
        If these accounts are inactive please perform the following:
        <ul>
            <li>Assign ticket to Service Desk Manager</li>
            <li>Note that the user is inactive</li>
            <li>Verify list with Service Desk Manager</li>
            <li>Move the account to "domain.com/Organization/Accounts/Retired/"</li>
            <li>Service Desk Manager will advise on what to add to the description field</li>
        </ul>
        <br>
        If these accounts are active please contact the user and assist them connecting to the domain.
        <br><br>
        Thank you,
        <br>
        IT Ops Team
    </body>
    </html>
"@

    Write-Output "Sending E-mail to $emailaddress..."
    Try {
        Send-MailMessage -To $emailToaddress -Cc $emailCcAddress -From $emailFrom -Subject $emailSubjectComp -Body $emailBodyComp -SmtpServer $emailSmtpServer -Priority High -DeliveryNotificationOption OnSuccess, OnFailure -BodyAsHtml -Attachments $emailAttachments
    } Catch {
        Write-Output "Unable to send e-mail"
    }
} Elseif (($ruserLogon).Count -ge 1 -and ($rcompLogon).Count -lt 1) {
    ForEach ($ruser in $ruserLogon) {
        $csvUserQuery = $ruser | Select-Object Name, @{N = "User Name"; E = "SamAccountName" }, @{N = "Last Logon"; E = "LastLogonDate" }, @{N = "AD Location"; E = "DistinguishedName" }
        $csvUserQuery | Export-Csv -NoTypeInformation -Append $DirPath\Removed-UserAccounts.csv -Force
    }

    $emailSubjectUser = "(Dry Run) Disabled or Removed Users"
    $emailBodyUser = @"
    <!DOCTYPE html>
    <html lang="en" dir="ltr">
    <head>
        <meta charset="utf-8">
        <title></title>
    </head>

    <body style="font-size: 14px; font-family: Tahoma;">
        Hello Service Desk Team,
        <br><br>
        These are the user accounts that were disabled or removed in Active Directory as of $Date please verify they are still active:
        <br><br>
        $emailRemovedUsers
        <br>
        If these accounts are inactive please perform the following:
        <ul>
            <li>Assign ticket to Service Desk Manager</li>
            <li>Note that the user is inactive</li>
            <li>Verify list with Service Desk Manager</li>
            <li>Move the account to "domain.com/Organization/Accounts/Retired/"</li>
            <li>Service Desk Manager will advise on what to add to the description field</li>
        </ul>
        <br>
        If these accounts are active please contact the user and assist them connecting to the domain.
        <br><br>
        Thank you,
        <br>
        IT Ops Team
    </body>
    </html>
"@

    Write-Output "Sending E-mail to $emailaddress..."
    Try {
        Send-MailMessage -To $emailToaddress -Cc $emailCcAddress -From $emailFrom -Subject $emailSubjectUser -Body $emailBodyUser -SmtpServer $emailSmtpServer -Priority High -DeliveryNotificationOption OnSuccess, OnFailure -BodyAsHtml -Attachments $emailAttachments
    } Catch {
        Write-Output "Unable to send e-mail"
    }
}

$currentTime = Get-Date
Write-Output "Script complete at" $currentTime
Stop-Transcript