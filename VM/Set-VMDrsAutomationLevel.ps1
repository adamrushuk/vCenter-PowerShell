$CpuCount = 16

$ClusterReport = Get-Cluster | Select-Object Name, DrsEnabled, DrsAutomationLevel
$ClusterReport

$AllVMs = Get-VM
Write-Host "$($AllVMs.count) VMs found"

$LargeCPUTargetVMs = $AllVMs | Where-Object {$_.NumCpu -ge $CpuCount}
Write-Host "$($LargeCPUTargetVMs.count) VMs found with $CpuCount or more vCPUs"

$DrsManualVMs = $LargeCPUTargetVMs | Where-Object {$_.DrsAutomationLevel -ne 'Manual'}
Write-Host "$($DrsManualVMs.count) VMs found with $CpuCount or more vCPUs and DrsAutomationLevel NOT set to 'Manual'`n"

$DrsManualVMs | Select-Object Name, NumCpu, PowerState, DrsAutomationLevel, VMHost, Cluster | Format-Table -AutoSize

# Set Drs to Manual
#$DrsManualVMs | Where {$_.DrsAutomationLevel -ne 'Manual'} | Set-VM -DrsAutomationLevel Manual -WhatIf
