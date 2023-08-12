<#
	.DESCRIPTION
        The purpose of this script is to remove expired or superceded updates from all software update nodes in SCCM 2012.
                
                Author: Ben Morris

                Credit: Trevor Sullivan for original script
                http://trevorsullivan.net/2011/11/29/configmgr-cleanup-software-updates-objects/
                
	.PARAMETER  ServerName
		The SCCM site serve that will be checked for expired and superceded content within any configuration.
	
	
	.EXAMPLE
	This example command line will target a primary site server.
	PS C:\> Remove-SCCMExpiredSupersededContent.ps1 -ServerName Server01

	.INPUTS
		System.String,System.Int32

	.OUTPUTS
		System.String

	.NOTES
	
	Maintenance:
 Date        By   Comments
 ----------  ---  ----------------------------------------------------------
 1/07/2012  BM  Obtained base script from Trevor Sulliva's blog.
 12/07/2012 BM - 0.2   - Commented out checking packages for expired and superceeded updates until package refresh issues is resolved.
 12/07/2012 BM - 0.9   - Corrected SU package refreshing. Will only now refresh packages that contained expired or superceeded updates.  
 15/07/2012 BM - 0.9.1 - Converted into an advanced script for help functions etc.
 12/03/2014 BM - 0.9.2 - Commented out section relating to 'SMS_UpdatesAssignment' (Deployments) as SCCM 2012 'Update Groups' mirror to this class automatically.
 12/03/2014 BM - 1.0 - Updates and tested on SCCM 2012 R2

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help
#>

[cmdletBinding()]
param(
[Parameter(mandatory=$true)][string]$ServerName
    )
$VerbosePreference = "continue"
$ServerName = $ServerName.ToUpper()
$PSConsole = (Get-Host).UI.RawUI
$PSConsole.WindowTitle = "SCCM Software Updates Clean up script - $ServerName"

function Get-SccmSiteCode
{
    param($ServerName)

    $SccmSiteCode = @(Get-WmiObject -Namespace root\sms -Class SMS_ProviderLocation -ComputerName $ServerName)[0].SiteCode
    Write-Output $SccmSiteCode
}

function Remove-SccmExpiredUpdates
{
    param(
        [Parameter(Mandatory = $true)]
        $SccmServer ,
        [Parameter(Mandatory = $false)]
        $SccmSiteCode ,
        [Hashtable]
        $PackageFilter = $null
    )

    process
    {
        # Turn on logging.
        $TranscriptFile = $ENV:Temp + '\Remove-SCCMExpiredSupersededContent.log'
        $(Get-Date -Format s)
       
        Start-Transcript -Path $TranscriptFile
        
        if (-not (Test-Connection $SccmServer) -and -not (Get-WmiObject -ComputerName $SccmServer -Namespace root -Class __NAMESPACE -Filter "Name = 'sms'"))
        {
            Write-Error "Could not find SCCM provider on $SccmServer"
            break
        }

        # Get the SCCM site code for the server
        if (-not $SccmSiteCode)
        {
            $SccmSiteCode = (Get-SccmSiteCode $SccmServer)
        }

        #region Clean up Update Lists
        # Remove expired updates from update (authorization) lists that are owned by this SCCM primary site
        $UpdateLists = @(Get-WmiObject -Namespace root\sms\site_$SccmSiteCode -Class SMS_AuthorizationList -ComputerName $SccmServer -Filter "SourceSite = '$SccmSiteCode'")
	    $Counter1 = 0
        $UpdateListCount = $UpdateLists.count
        foreach ($UpdateList in $UpdateLists)
        {
            # The Updates property on SMS_AuthorizationList is a lazy property,
            # so we must get a direct reference to the WMI object
            $UpdateList = [wmi]"$($UpdateList.__PATH)"
            Write-Progress -id 1 -activity "Checking All Update Lists: " -status "Percent completed: " -PercentComplete (($Counter1/$UpdateListCount)*100)
            Write-Host "Update List: $($UpdateList.LocalizedDisplayName) has $($UpdateList.Updates.Count) updates in it"
		    $Counter1++
			# For each update list object, iterate over update IDs and test if they are expired or superseded.
            $Counter2 = 0
			$ItemCount1 = $UpdateList.Updates.count
            foreach ($UpdateId in $UpdateList.Updates)
            {
                # Write-Verbose "Testing if update ID $UpdateId is expired"
                Write-Progress -id 2 -activity "Update List: $($UpdateList.LocalizedDisplayName) \\ UpdateID: $UpdateId" -status "Percent completed: " -PercentComplete (($Counter2/$ItemCount1)*100)
                $Counter2++
                # If update is expired, then remove it from the list of updates assigned to this update list
                if (Test-SccmUpdateExpired -SccmServer $SccmServer -UpdateId $UpdateId)
                {
                    $UpdateList.Updates = @($UpdateList.Updates | ? { $_ -ne $UpdateId })
                    Write-Host ("Update count is now: " + $UpdateList.Updates.Count)
                }
            }

            # Commit the Update List back to the SCCM provider
            $UpdateList.Put()
        }
        #endregion
<#
 # 
 NOTE: This code section is only appliable for SCCM 2007. In 2012 when an update is removed from an Update deployment Group it automatically cleans up the deployment WMI classes.

        #region Clean up Update Assignments (Deployment Management)
        # Get a list of all Deployment Management objects that are owned by this SCCM site
        $UpdatesAssignments = Get-WmiObject -Namespace root\sms\site_$SccmSiteCode -Class SMS_UpdatesAssignment -ComputerName $SccmServer -Filter "SourceSite = '$SccmSiteCode'"

        # For each update assignment, get a list of CIs and filter out expired updates
        $Counter3 = 0
		foreach ($UpdatesAssignment in $UpdatesAssignments)
        {
            $UpdatesAssignment = [wmi]"$($UpdatesAssignment.__PATH)"
            Write-Verbose "Deployment: $($UpdatesAssignment.AssignmentName) has $($UpdatesAssignment.AssignedCIs.Count) updates in it."			
            Write-Progress -id 1 -activity "Checking All Software Update Deployments: " -status "Percent completed: " -PercentComplete (($Counter3/$UpdatesAssignments.Count)*100)        
            $Counter3++
            $Counter4 = 0
			$ItemCount2 = $UpdatesAssignment.AssignedCIs.count
            foreach ($UpdateId in $UpdatesAssignment.AssignedCIs)
            {
                # Write-Verbose "Testing if update ID $UpdateId is expired"
				Write-Progress -id 2 -activity "Deployment Name: $($UpdatesAssignment.AssignmentName) \\ UpdateID: $UpdateId" -status "Percent completed: " -PercentComplete (($Counter4/$ItemCount2)*100)
                $Counter4++
                # Test if the update is expired or superseded
                if (Test-SccmUpdateExpired -SccmServer $SccmServer -UpdateId $UpdateId)
                {
                    # Remove the update from the array of update IDs assigned to this updates assigment object
                    $UpdatesAssignment.AssignedCIs = @($UpdatesAssignment.AssignedCIs | ? { $_ -ne $UpdateId })
                    Write-Verbose ("Update count is now: " + $UpdatesAssignment.AssignedCIs.Count)
                }
            }

            #Write-Debug "Write the modified updates assignment object back to the provider?"
            #$UpdatesAssignment.Put();
        }
        #endregion
#>
        #region Clean up Software Update Packages

        # Software packages are a little bit different from the other software updates objects. This is how the various objects relate:
        # SMS_SoftwareUpdate <-> SMS_CiToContent <-> SMS_PackageToContent <-> SMS_SoftwareUpdatesPackage
        # http://social.technet.microsoft.com/Forums/en-US/configmgrsdk/thread/fc68ced0-e39a-4ea2-b59d-c2efa2695b1d#fc68ced0-e39a-4ea2-b59d-c2efa2695b1d

        $ExpiredContentQuery = "Select SMS_PackageToContent.ContentID,SMS_PackageToContent.PackageID from SMS_SoftwareUpdate
                                join SMS_CIToContent on SMS_CIToContent.CI_ID = SMS_SoftwareUpdate.CI_ID
                                join SMS_PackageToContent on SMS_CIToContent.ContentID = SMS_PackageToContent.ContentID
                                where SMS_PackageToContent.PackageID like '%$SCCMSiteCode%' and SMS_SoftwareUpdate.IsExpired = 'true' or SMS_SoftwareUpdate.IsSuperseded = '1'"
                                
        $ExpiredPackageQuery2 = "Select DISTINCT SMS_PackageToContent.PackageID from SMS_SoftwareUpdate
                                join SMS_CIToContent on SMS_CIToContent.CI_ID = SMS_SoftwareUpdate.CI_ID
                                join SMS_PackageToContent on SMS_CIToContent.ContentID = SMS_PackageToContent.ContentID
                                where SMS_PackageToContent.PackageID like '%$SCCMSiteCode%' and SMS_SoftwareUpdate.IsExpired = 'true' or SMS_SoftwareUpdate.IsSuperseded = '1'"

        if ($PackageFilter)
        {
            $ExpiredContentQuery = $ExpiredContentQuery + " and SMS_PackageToContent.PackageID = '$($PackageFilter.PackageID)'"
        }
        #Getting a list of expired content needing removal and unique list of SU pacakges to then be refreshed.
        $ExpiredContentList = $null
        $ExpiredContentList = @(Get-WmiObject -ComputerName $SccmServer -Namespace root\sms\site_$SccmSiteCode -Query $ExpiredContentQuery)
		$PackagesRefreshList = $null
        $PackagesRefreshList  = @(Get-WmiObject -ComputerName $SccmServer -Namespace root\sms\site_$SccmSiteCode -Query $ExpiredPackageQuery2)
		$Counter5 = 0
		$ItemCount3 = $ExpiredContentList.count
        # For each update package, get a list of CIs and filter out expired or superseded updates
        Foreach ($ExpiredContent in $ExpiredContentList)
            {
                Write-Verbose "Removing content ID $($ExpiredContent.ContentID) from package $($ExpiredContent.PackageID)"
      			Write-Progress -id 1 -activity "Removing content from Package: $ExpiredContent" -status "Percent completed: " -PercentComplete (($Counter5/$ItemCount3)*100)
                $Counter5++
                # Retrieve the instance of the Software Updates Package that contains the content
                $SoftwareUpdatesPackage = [wmi]"\\$SccmServer\root\sms\site_$($SccmSiteCode):SMS_SoftwareUpdatesPackage.PackageID='$($ExpiredContent.PackageID)'"

                # Remove all expired or superseded updates based on their ID from the update package
                If ($SoftwareUpdatesPackage.RemoveContent($ExpiredContent.ContentID, $false).ReturnValue -eq 0)
                    {
                        Write-Host "Successfully removed $($ExpiredContent.ContentID) from $($ExpiredContent.PackageID)"
                    }
            }
		
        If ($PackagesRefreshList.Count -gt 0)
            {
                $Counter6 = 0
                Write-Verbose "$($PackagesRefreshList.count) packages will be refreshed."
    			Write-Verbose "$PackagesRefreshList"
                
                Foreach ($RefreshPackage in $PackagesRefreshList)
                    {
                    Write-Verbose "Refreshing package content $RefreshPackage.PackageID"
        			Write-Progress -id 4 -activity "Refreshing Package: $($RefreshPackage.PackageID)" -status "Percent completed: " -PercentComplete (($Counter6/$PackagesRefreshList.count)*100)
                    $PackageID = $($RefreshPackage.PackageID)
                    $SoftwareUpdatesPackage =  Get-WmiObject -ComputerName $SccmServer -Namespace root\sms\site_$SccmSiteCode -query "Select * from SMS_SoftwareUpdatesPackage where PackageID = '$PackageID'"
                    $Counter6++
                    Write-Debug "Attempt package refresh?"
                    If ($SoftwareUpdatesPackage.RefreshPkgSource().ReturnValue -eq 0)
                            {
                                Write-Verbose ("Successfully refreshed package source for: " + $SoftwareUpdatesPackage.PackageID +" - " + $SoftwareUpdatesPackage.Name)
            					Start-Sleep -s 3
                            }
                    }
            }
        Else
            {
                Write-Verbose "No expired or superseded content found in any packages. Skipping package refreshes."
            }
        #endregion
    }
}

function Test-SccmUpdateExpired
{
    param(
        [Parameter(Mandatory = $true)]
        $SccmServer,
        [Parameter(Mandatory = $false)]
        $SccmSiteCode,
        [Parameter(Mandatory = $true)]
        $UpdateId
    )

    # Get the SCCM site code for the server
    if (-not $SccmSiteCode) {
        $SccmSiteCode = (Get-SccmSiteCode $SccmServer)
    }
    # Find update that is expired or superseded with the specified CI_ID (unique ID) value
    $ExpiredUpdateQuery = "select * from SMS_SoftwareUpdate where (IsExpired = 'true' or IsSuperseded = '1') and CI_ID = '$UpdateId'"
    $Update = @(Get-WmiObject -ComputerName $SccmServer -Namespace root\sms\site_$SccmSiteCode -Query $ExpiredUpdateQuery)

    # If the WMI query returns more than 0 instances (should NEVER be more than 1 at most), then the update is expired.
    if ($Update.Count -gt 0)
    {
        Write-Verbose ("Found an Expired or Superseded software update (KB$($Update[0].ArticleID)) with ID " + $Update[0].CI_ID )
        return $true
    }
    else
    {
        return $false
    }
    Stop-Transcript
	Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Clear-Host
Remove-SccmExpiredUpdates -SccmServer $ServerName
