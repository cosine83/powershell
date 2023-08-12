$getEncStatus = Get-BitLockerVolume -MountPoint "C:"
#Get encryption method, encryption on, and amount of drive encrypted
$getEncStatus.EncryptionMethod
$getEncStatus.ProtectionStatus
$getEncStatus.EncryptionPercentage