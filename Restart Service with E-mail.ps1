$Server = "testPC"
$SMTP = "mail.test.com"
$From = "scheduledtask@test.com"
$To = "me@test.com"
$Date = Get-Date -format "MM.dd.yyy HH:mm"
$Stopped = $false
$LogExists = $false

If ($LogExists) {
	Try {
		New-EventLog -LogName Application -Source "Scheduled Task" -ErrorAction SilentlyContinue
		$LogExists = $true
	}
	Catch {
		Return $null
		$LogExists = $true
	}
}
If (!$LogExists) {
	Write-Host "Event log already exists"
}
If ($Stopped) {
	Try {
		$Stop = Get-Service -ComputerName $Server -Name Test | Set-Service -Status Stopped -Verbose -ErrorAction Stop
		Write-EventLog -LogName Application -Source "Scheduled Task" -EntryType Information -EventID 1337 -Message "Successfully stopped the Test service."
		$Stopped = $true
	}
	Catch {
		Write-EventLog -LogName Application -Source "Scheduled Task" -EntryType Error -EventID 1337 -Message "Failed to stop the Test service."
		Send-MailMessage -SmtpServer $SMTP -From $From -To $To -Subject "Scheduled Task" -Body "Failed to stop the Test service on $Date!"
		Break 
	}
}
If (!$Stopped)
{
	Try {
		$Start = Get-Service -ComputerName $Server -Name Test | Set-Service -Status Running -Verbose -ErrorAction Stop
		Write-EventLog -LogName Application -Source "Scheduled Task" -EntryType Information -EventID 1337 -Message "Successfully restarted the Test service."
		Send-MailMessage -SmtpServer $SMTP -From $From -To $To -Subject "Scheduled Task" -Body "The scheduled task completed and restarted the Test Service Successfully on $Date!"
	}
	Catch {
		Write-EventLog -LogName Application -Source "WFTD Scheduled Task" -EntryType Error -EventID 1337 -Message "Failed to start theTest service."
		Send-MailMessage -SmtpServer $SMTP -From $From -To $To -Subject "Scheduled Task" -Body "Failed to start the Test Service on $Date!"
		Break 
	}
}
Else {
	Send-MailMessage -SmtpServer $SMTP -From $From -To $To -Subject "Scheduled Task" -Body "The scheduled task completed but ran into errors on $Date!"
}
