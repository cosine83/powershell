#Logging and file transfer directories
$dirPath = "C:\Scripts\Install-UniversalFonts"
$tempPath = "C:\temp"
$fontsPath = "C:\temp\Fonts"

#Check if logging directory is present
$dirPathCheck = Test-Path -Path $DirPath
$tempPathCheck = Test-Path -Path $tempPath
$fontsPathCheck = Test-Path -Path $fontsPath

#Create logging directory if it doesn't exist
If (!($DirPathCheck)) {
    New-Item -ItemType Directory $DirPath -Force
}

If (!($tempPathCheck)) {
    New-Item -ItemType Directory $tempPath -Force
}

If (!($fontsPathCheck)) {
    New-Item -ItemType Directory $fontsPath -Force
}


#Don't forget to declare your variables
function Get-ComputerADSite {
    param(
        [parameter(Mandatory=$false)]
        [string]$ComputerName = "$env:ComputerName"
    )
    ($site= nltest /server:$computername /dsgetsite) 2>&1> $null
    if ($lastexitcode -eq 0) {
        $site[0]
    }
}

$compAdSite = Get-ComputerADSite

Switch ($compAdSite) {
    "Site A" { Copy-Item -Path "\\serverName\sourcefolder\fonts.zip" -Destination "$($tempPath)" -Recurse }
    "Site B" {Copy-Item -Path "\\serverName\sourcefolder\fonts.zip" -Destination "$($tempPath)" -Recurse  }
    "Site C" { Copy-Item -Path "\\serverName\sourcefolder\fonts.zip" -Destination "$($tempPath)" -Recurse  }
    "Site B" { Copy-Item -Path "\\serverName\sourcefolder\fonts.zip" -Destination "$($tempPath)" -Recurse  }
}

Expand-Archive -Path "$($tempPath)\fonts.zip" -Destination $($fontsPath) -Force
$systemFontsPath = "C:\Windows\Fonts"
$getFonts = Get-ChildItem $fontsPath -Include '*.ttf','*.ttc','*.otf' -recurse

foreach($fontFile in $getFonts) {
	$targetPath = Join-Path $systemFontsPath $fontFile.Name
	if(Test-Path -Path $targetPath){
		$FontFile.Name + " already installed"
	}
	else {
		"Installing font " + $fontFile.Name
		#Extract Font information for Reqistry
		$ShellFolder = (New-Object -COMObject Shell.Application).Namespace($fontsPath)
		$ShellFile = $shellFolder.ParseName($fontFile.name)
		$ShellFileType = $shellFolder.GetDetailsOf($shellFile, 2)
		#Set the $FontType Variable
		If ($ShellFileType -Like '*TrueType font file*') {$FontType = '(TrueType)'}
		#Update Registry and copy font to font directory
		$RegName = $shellFolder.GetDetailsOf($shellFile, 21) + ' ' + $FontType
		New-ItemProperty -Name $RegName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $fontFile.name -Force | out-null
		Copy-item $fontFile.FullName -Destination $systemFontsPath
		"Done"
	}
}