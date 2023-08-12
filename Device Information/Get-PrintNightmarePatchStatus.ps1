#PrintNightmare patch sensor

If (Get-HotFix -Id KB5004945,KB5004946,KB5004947,KB5004948,KB5004950) {
    return $true
}
else {
    return $false
}