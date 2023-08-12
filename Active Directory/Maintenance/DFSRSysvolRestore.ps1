<#
----------------------------------------
File: DFSRSysvolRestore.ps1
Version: 1.0
Author: Thomas Bouchereau
-----------------------------------------

Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages 
 #>



function set-AuthDFSRSysvol
    {

    <# 
.SYNOPSIS
Set the values msdfsr-Enabled of a specified server to perform an Authoritative Restore of a DFSR replicated SYSVOL.

.DESCRIPTION

This function purpose is to configure the value of the attributes msdfsr-Enabled and msdfsr-options on a server that you want to set as authoritative for a SYSVOL restore.
It is based on the step discribed on the following KB:
"How to force an authoritative and non-authoritative synchronization for DFSR-replicated SYSVOL (like "D4/D2" for FRS")
< http://support.microsoft.com/kb/2218556>


.PARAMETER 
-Server: shortname of the server that you want to set as authoritative for SYSVOL
-step: values can be 1 or 2. They correspond to the 2 steps of configuration that are necessary to do an authoritative restore of SYSVOL.



.OUTPUTS

No output

.EXAMPLE

set-authDFSRSYSVOL -server 2012DC -step 1

This command will set the following value to the attributes msdfsr-Enabled and msdfsr-options.
msdfsr-Enable: FALSE
msdfsr-Options: 1

You can verifiy by using the command get-sysvoldfsrconf -server 2012DC

.EXAMPLE

set-authDFSRSYSVOL -server 2012DC -step 2

This command will set the following value to the attributes msdfsr-Enabled
msdfsr-Enable: TRUE

You can verifiy by using the command get-sysvoldfsrconf -server 2012DC


#>
    [cmdletBinding()]
    param ([parameter(mandatory=$true)]$server,[parameter(mandatory=$true)]$step)
    $domain=get-addomain
    
    
     if ((test-connection -ComputerName $server -count 1).statuscode -eq 0 2>$null)
                {
                    $obj=get-adobject -identity "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$($server),OU=Domain Controllers,$($domain.distinguishedname)" -properties *
                    switch ($step)
                        {
                            "1"{
                            $obj.'msDFSR-Enabled'=$FALSE
                            $obj.'msDFSR-options'=1
                            set-adobject -instance $obj
                            }
                            "2"{
                            $obj.'msDFSR-Enabled'=$TRUE
                            set-adobject -instance $obj                
                            }
                            default {"$step is not a valid value for step. It must be 1 or 2"}
                         }
                }
            else 
                {
                    Write-host "Server $server unavailable or does not exist"
                }

     
    
    }


function set-NonAuthDFSRSysvol
    {

    <# 
.SYNOPSIS
Set the values msdfsr-Enabled of a specified server to performe a Non-Authoritative Restore of a DFSR replicated SYSVOL.

.DESCRIPTION

This function purpose is to configure the value of the attribute msdfsr-Enabled on a server that you want to set for a non-authoritative for a SYSVOL restore.
"How to force an authoritative and non-authoritative synchronization for DFSR-replicated SYSVOL (like "D4/D2" for FRS")
< http://support.microsoft.com/kb/2218556>


.PARAMETER 
-Server: shortname of the server that you want to set for a non-authoritative for SYSVOL
-step: values can be 1 or 2. They correspond to the 2 steps of configuration that are necessary to do an authoritative restore of SYSVOL.



.OUTPUTS

No output

.EXAMPLE

set-NonauthDFSRSYSVOL -server 2012DC -step 1

This command will set the following value to the attributes msdfsr-Enabled.
msdfsr-Enable: FALSE


You can verifiy by using the command get-sysvoldfsrconf -server 2012DC

.EXAMPLE

set-NonauthDFSRSYSVOL -server 2012DC -step 2

This command will set the following value to the attributes msdfsr-Enabled
msdfsr-Enable: TRUE

You can verifiy by using the command get-sysvoldfsrconf -server 2012DC

#>


    [cmdletBinding()]
    param ([parameter(mandatory=$true)]$server,[parameter(mandatory=$true)]$step)
    $domain=get-addomain
    
    
     if ((test-connection -ComputerName $server -count 1).statuscode -eq 0 2>$null)
                {
                    $obj=get-adobject -identity "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$($server),OU=Domain Controllers,$($domain.distinguishedname)" -properties *
                     switch ($step)
                        {
                            "1"{
                            $obj.'msDFSR-Enabled'=$FALSE
                            set-adobject -instance $obj
                            }
                            "2"{
                            $obj.'msDFSR-Enabled'=$TRUE
                            set-adobject -instance $obj
                            }
                            default {"$step is not a valid value for step. It must be 1 or 2"}
                         }
                }
            else 
                {
                    Write-host "Server $server unavailable or does not exist"
                }

    
    }


function get-SysvolDFSRConf
    {

    <# 
.SYNOPSIS
return value of attribut msdfsr-Enabled and msdfsr-Options for a specified server

.DESCRIPTION
This function purpose is to list the msdfsr-Enabled and msdfsr-Options attribute of a specidied server.
Those attributes are present on servers that are part of a DFSR replication.


.PARAMETER Path: shortname of the DC you want to check.


.INPUTS
shortname of the DC you want to check

.OUTPUTS
msdfsr-Enabled for <server name>: <True|False>
msdfsr-options for <server name>: <0|1>

.EXAMPLE

get-dfsrsysvolconf -server 2012DC


#>
    [cmdletBinding()]
    param ([parameter(mandatory=$true)]$server)
    $domain=get-addomain
    

    if ((test-connection -ComputerName $server -count 1).statuscode -eq 0 2>$null)
                {
                        
                     $obj=get-adobject -identity "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$($server),OU=Domain Controllers,$($domain.distinguishedname)" -properties *
                     "msDFSR-Enabled for $($server): $($obj.'msDFSR-Enabled')"
                     "msDFSR-options for $($server): $($obj.'msDFSR-options')"
                }
            else 
                {
                    Write-host "Server $server unavailable or does not exist"
                }

    

    }


