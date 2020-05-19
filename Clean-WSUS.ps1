$wsus = Get-WSUSServer -Name server.domain.com -Port 8531
$db = $wsus.GetDatabaseConfiguration().CreateConnection()
$db.QueryTimeOut = 1500
$db.connect()
$toCleanUp = $db.GetDataSet("EXECUTE spGetObsoleteUpdatesToCleanup", [System.Data.CommandType]::Text)
$left = $toCleanUp.Tables[0].Rows.Count
write-host (get-date): $left updates to be removed
Foreach ($row in $toCleanUp.Tables[0]) {
    $db.Close()
    $db.Connect()
    write-host (get-date): Removing ID $row.LocalUpdateID: ($left = $left - 1) remaning
    $db.ExecuteCommandNoResult("EXECUTE spDeleteUpdate @localUpdateID=" + $row.LocalUpdateID, [System.Data.CommandType]::Text)
}write-host (get-date): Starting cleanup wizard
Invoke-WsusServerCleanup -CleanupObsoleteComputers -CleanupObsoleteUpdates -CleanupUnneededContentFiles -DeclineExpiredUpdates -DeclineSupersededUpdates
write-host (get-date): Compressing Updates
Invoke-WsusServerCleanup -CompressUpdates
