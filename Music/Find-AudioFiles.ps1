<#
.PURPOSE
The purpose of this script is to search local drives for audio files >10s or longer and move them to a single folder for organization into a single audio library.
The below snippets from the linked pages are the bases and will be worked with the make a final product.

.LINKS

.TODO

.NOTES
Created By: Justin Grathwohl
Date Created:
Date Updated:

#>

#Test snippets from the internet
# https://superuser.com/questions/704575/get-song-duration-from-an-mp3-file-in-a-script
$path = 'M:\Musikk\awesome_song.mp3'
$shell = New-Object -COMObject Shell.Application
$folder = Split-Path $path
$file = Split-Path $path -Leaf
$shellfolder = $shell.Namespace($folder)
$shellfile = $shellfolder.ParseName($file)

write-host $shellfolder.GetDetailsOf($shellfile, 27);

# https://social.technet.microsoft.com/Forums/lync/en-US/c081d8b8-34dd-41f6-b1d0-eb82c8077318/get-length-of-audio-files-and-export-to-csv-powershell-script?forum=winserverpowershell
$folder= 'C:\TestAudio'

$com = (New-Object -ComObject Shell.Application).NameSpace($folder)
for($i = 0; $i -lt 64; $i++) {
	$name = $com.GetDetailsOf($com.Items, $i)
	if ($name -eq 'Length') { $lengthattribute = $i}
}
$com.Items() |
	ForEach-Object {
		[PSCustomObject]@{
			Name = $_.Name
			Size = $com.GetDetailsOf($_, 1)
			DateCreated = $com.GetDetailsOf($_, 4)
			Length = $com.GetDetailsOf($_, $lengthattribute)
		}
	} |
	Export-Csv -Path c:\Scripts\audiolength.csv -Encoding ascii -NoTypeInformation

# https://stackoverflow.com/questions/58830853/powershell-get-video-duration-and-list-all-files-recursively-export-to-csv
$Directory = "D:\My Source Folder"
$Shell = New-Object -ComObject Shell.Application
Get-ChildItem -Path $Directory -Recurse -Force | ForEach-Object {
    $Folder = $Shell.Namespace($_.DirectoryName)
    $File = $Folder.ParseName($_.Name)
    $Duration = $Folder.GetDetailsOf($File, 27)
    [PSCustomObject]@{
        Name = $_.Name
        Size = "$([int]($_.length / 1mb)) MB"
        Duration = $Duration
    }
} | Export-Csv -Path "./temp.csv" -NoTypeInformation

# https://geekeefy.wordpress.com/2016/10/15/powershell-get-mp3mp4-files-metadata-and-how-to-use-it-to-make-you-life-easy/
Function Get-MediaMetadata
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([Psobject])]
    Param (
        [String] [Parameter(Mandatory=$true, ValueFromPipeline=$true)] $Directory
    )
    Begin {
        $shell = New-Object -ComObject "Shell.Application"
    }
    Process {
        Foreach($Dir in $Directory) {
            $ObjDir = $shell.NameSpace($Dir)
            $Files = Get-ChildItem $Dir| Where-Object{$_.Extension -in '.mp3','.mp4'}
            Foreach($File in $Files) {
                $ObjFile = $ObjDir.parsename($File.Name)
                $MetaData = @{}
                $MP3 = ($ObjDir.Items()|Where-Object{$_.path -like "*.mp3" -or $_.path -like "*.mp4"})
                $PropertArray = 0,1,2,12,13,14,15,16,17,18,19,20,21,22,27,28,36,220,223
                Foreach($item in $PropertArray) {
                    If($ObjDir.GetDetailsOf($ObjFile, $item)) { #To avoid empty values
                        $MetaData[$($ObjDir.GetDetailsOf($MP3,$item))] = $ObjDir.GetDetailsOf($ObjFile, $item)
                    }
                }
                New-Object psobject -Property $MetaData |Select-Object *, @{n="Directory";e={$Dir}}, @{n="Fullname";e={Join-Path $Dir $File.Name -Resolve}}, @{n="Extension";e={$File.Extension}}
            }
        }
    }
    End {
    }
}