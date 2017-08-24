$vm = "VM01"

$vmtest = Get-vm $vm | get-view
$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

# enable ctk
$vmConfigSpec.changeTrackingEnabled = $true
$vmtest.reconfigVM($vmConfigSpec)
$snap = New-Snapshot $vm -Name "Enable CBT"
$snap | Remove-Snapshot -confirm:$false
