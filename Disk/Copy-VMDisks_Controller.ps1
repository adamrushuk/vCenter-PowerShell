# Load functions
. ".\Copy-VMDisks.ps1"

# LIVE SOURCE VM
$SourceVMName = "SourceVM01"

# LIVE DESTINATION VM
$DestinationVMName = "DestinationVM02"

# Connect to vCenter
Connect-VIServer vCenterServer01

# Verbose
Copy-VMDisks -SourceVMName $SourceVMName -DestinationVMName $DestinationVMName -Verbose -Confirm:$false