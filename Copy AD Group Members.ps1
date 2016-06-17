#Copy AD group members from one group to another

$query = Get-ADGroup -Filter * | Where {$_.Name -eq ""} | Get-ADGroupMember
$Group = $query.SamAccountName
$AddTo = ""

foreach ($user in $Group) {
	Add-ADGroupMember -Identity "$AddTo" -Members $user
}
