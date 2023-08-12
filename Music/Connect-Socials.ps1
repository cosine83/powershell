<#
.PURPOSE
The purpose of this script is to automate posting a random, unposted photo to my photography socials



.LINKS

.TODO

.NOTES
Created By: Justin Grathwohl
Date Created:
Date Updated:

#>

#Check for and install any required modules


#Create functions for the platforms' API connections
Function Connect-MetaFacebook {
    $fbConnect = @{
        "clientId"       = ""
        "clientSecret"   = ""
        "accessTokenUri" = ""
        "callbackUrl"    = ""
    }

    #Create OAuth token request body
    $body = @{
        grant_type    = "client_credentials"
        client_id     = $fbConnect.clientId
        client_secret = $fbConnect.clientSecret
    }

    #Request Meta OAuth client token from VMWare OAuth service
    try {
        $response = Invoke-WebRequest -Method Post -Uri "$($fbConnect.accessTokenUri)" -Body $body -UseBasicParsing
        $response = $response | ConvertFrom-Json
        $oauth_token = [string]$($response.access_token)
    } catch {
        $ErrorMessage = $PSItem | ConvertFrom-Json
        Write-Log "Failed to create OAuth Token for: $env with following ErrorCode: $($ErrorMessage.errorCode) - $($ErrorMessage.message)" -ForegroundColor Red
    }
    Return $oauth_token
}

#API connect variables for the platforms
$connectInstagram = ""
$connectFacebook = ""
$connectTwitter = ""
$connectPatreon = ""