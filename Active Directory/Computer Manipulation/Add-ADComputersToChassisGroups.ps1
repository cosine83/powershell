$getAdComputers = Get-ADComputer -Filter {OperatingSystem -NotLike "*Server*"} -Properties *
forEach ($adComputer in $getAdComputers) {
    $pingAdComputer = Test-Connection -TargetName $adComputer -Count 1 -Quiet
    $testWsMan = Test-WSMan -ComputerName $adComputer
    If ($pingAdComputer) {
        If ($testWsMan){
            $getChassisType = Get-CimInstance Win32_SystemEnclosure -ComputerName $adComputer.Name | Select-Object -ExpandProperty ChassisTypes
            If ('3', '4', '5', '6', '7', '15', '16', '34', '35', '36' -eq $getChassisType) {
                Write-Output $($adComputer).Name "is a desktop chassis type"
                $adComputer | Select-Object Name,DistinguishedName,OperatingSystem,OperatingSystemVersion,@{N="ChassisType";E={$getChassisType}} | Export-Csv -Append -NoTypeInformation "C:\temp\desktopChassisComputers.csv"
                #Add-ADGroupMember -Identity "Desktops" -Members $adComputer
            }
            Elseif ('8', '9', '10', '11', '12', '14', '18', '21', '31', '32' -eq $getChassisType) {
                Write-Output $($adComputer).Name "is a laptop chassis type"
                $adComputer | Select-Object Name,DistinguishedName,OperatingSystem,OperatingSystemVersion,@{N="ChassisType";E={$getChassisType}} | Export-Csv -Append -NoTypeInformation "C:\temp\laptopChassisComputers.csv"
                #Add-ADGroupMember -Identity "Laptops" -Members $adComputer
            }
            Elseif ('17', '23' -eq $getChassisType) {
                Write-Output $($adComputer).Name "is a server chassis type"
                $adComputer | Select-Object Name,DistinguishedName,OperatingSystem,OperatingSystemVersion,@{N="ChassisType";E={$getChassisType}} | Export-Csv -Append -NoTypeInformation "C:\temp\serverChassisComputers.csv"
                #Add-ADGroupMember -Identity "Servers" -Members $adComputer
            }
            Elseif ('0', '1', '2', $null -eq $getChassisType) {
                Write-Output $($adComputer).Name "is an unknown chassis type"
                $adComputer | Select-Object Name,DistinguishedName,OperatingSystem,OperatingSystemVersion,@{N="ChassisType"; E={$getChassisType}} | Export-Csv -Append -NoTypeInformation "C:\temp\unknownChassisComputers.csv"
                #Add-ADGroupMember -Identity "Unknown Chassis" -Members $adComputer
            }
        }
        Else {
            Write-Output $adComputer.Name "is not enabled for PowerShell remoting."
            $adComputer | Select-Object Name,DistinguishedName,OperatingSystem,OperatingSystemVersion | Export-Csv -Append -NoTypeInformation "C:\temp\nopsremotingComputers.csv"
        }
    }
    Else {
        Write-Output $adComputer.Name "does not ping."
        $adComputer | Select-Object Name,DistinguishedName,OperatingSystem,OperatingSystemVersion | Export-Csv -Append -NoTypeInformation "C:\temp\offlineComputers.csv"
    }
}