#Clear Recycler contents on shared folders
$Property = Read-Host "What property's recycler are you clearing?"
$ErrorActionPreference = "SilentlyContinue"
If ($Property -eq "X") { $homefolder='\\domain\dfs1\homeshares' }
If ($Property -eq "X2") { $homefolder='\\domain\dfs2\homeshares' }
If ($Property -eq "X3") { $homefolder='\\domain\dfs3\homeshares' }
New-PSDrive -name "recyclers" -PSProvider FileSystem -Root $homefolder
 
Get-ChildItem -Path "recyclers:" -Force -Recurse | `
       ? {($_.fullname -match 'recycle.bin') -and ((Get-Date).AddDays(-1) -gt $_.LastWriteTime) -and ($_.PSIsContainer)} | `
       % {gci -Recurse -Force $_.fullname } | ? { ! $_.PSIsContainer } | `
       % {
	$a = $_.fullname
	$a = $a.replace($homefolder , 'recyclers:')
	write-host $_.LastAccessTime"--"$_.LastWriteTime"--"$a
	$a | remove-item -force -recurse
	}
	
Get-ChildItem -Path "recyclers:" -Filter desktop.ini -Force -Recurse | ForEach ($_) { remove-item $_.fullname -force }
Remove-PSDrive -Name "recyclers"