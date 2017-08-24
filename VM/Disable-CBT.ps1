$vm = "VM01"

$vmtest = Get-vm $vm | get-view
$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

# disable ctk
$vmConfigSpec.changeTrackingEnabled = $false
$vmtest.reconfigVM($vmConfigSpec)
$snap = New-Snapshot $vm -Name "Disable CBT"
$snap | Remove-Snapshot -confirm:$false
