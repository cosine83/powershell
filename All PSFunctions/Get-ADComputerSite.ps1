function Get-ADComputerSite {
    param(
        [parameter(Mandatory=$false)]
        [string]$ComputerName = "$env:ComputerName"
    )
    ($site= nltest /server:$computername /dsgetsite) 2>&1> $null
    if ($lastexitcode -eq 0) {
        $site[0]
    }
}