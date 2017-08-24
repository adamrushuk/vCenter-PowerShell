# Load functions
. ".\Copy-VMDisksSpecificDisks.ps1"

# SOURCE VM
$SourceVMName = "VM1"

# DESTINATION VM
$DestinationVMName = "VM2"

# Connect to vCenter
Connect-VIServer vCenterServer01

# Key is source disk, value is destination disk
<#
$DisksMaps = @{
    1 = 3
    3 = 4
    4 = 5
}
#>
# Disk numbers in vcenter start from 1 (not 0 like in vCD), so increment by 1
$DisksMaps = @{
    2 = 4
    4 = 5
    5 = 6
}

# Remove -WhatIf to take action
Copy-VMDisks -SourceVMName $SourceVMName -DestinationVMName $DestinationVMName -DiskMapping $DisksMaps -Confirm:$false -WhatIf
