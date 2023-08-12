# Returns the value of the Windows Product Key
# Return Type: String
# Execution Context: System

$key = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object { $_.PartialProductKey -ne $null } | Select-Object Description, LicenseStatus, PartialProductKey
Write-Output $key.PartialProductKey