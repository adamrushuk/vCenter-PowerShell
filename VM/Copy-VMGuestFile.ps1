<#
$vCenterName = 'vcenter01'
Connect-VIServer $vCenterName
#>

$CopyParams = @{
    Source = 'C:\GuestVM\Folder'
    Destination = 'C:\Local\Folder'
    VM = 'VM01'
    GuestToLocal = $true
    GuestUser = 'USERNAME'
    GuestPassword = 'PASSWORD'
}
Copy-VMGuestFile @CopyParams -Verbose
