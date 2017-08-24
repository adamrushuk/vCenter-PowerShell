<#
Check CBT for  vApp Templates
Connect-VIServer vCenterServer01

Example vApp Template name ('this is a folder in vCenter'):
sc-12345678-1234-5678-1234-abcdef123456 (12345678-1234-5678-1234-abcdef123456)

#>
# 1-22-33-abc123 (12345678-1234-5678-1234-abcdef123456) is the top-level Org folder
$FolderName = 'Company01 - Development (Tier01)'
$OrgFolder = Get-Folder -Name $FolderName

$ChildFolders = Get-Folder -Name 'sc-*' -Location $OrgFolder
$ChildFolders.Count

# Get vCenter VMs (these are vCloud vApp Templates)
$CIvAppTemplates = Get-VM -Location $ChildFolders
$CIvAppTemplates.Count

# Report on CBT setting
$Report = $CIvAppTemplates | Select-Object @{n = 'vApp Template'; e = {$_.Folder}},
    @{n = 'VM Name'; e = {$_.Name}}, @{n = 'CBT Enabled'; e = {$_.ExtensionData.Config.ChangeTrackingEnabled}}
$Report | Format-Table -AutoSize

$CIvAppTemplatesCBTEnabled = $CIvAppTemplates | Where-Object { $_.ExtensionData.Config.ChangeTrackingEnabled -eq 'True' }
$CIvAppTemplatesCBTEnabled.Count

# Loop through vApps
foreach ($VM in $CIvAppTemplatesCBTEnabled) {

    # Get the VM view
    $VMView = $VM | Get-View
    $VMConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

    # Disable CBT
    $VMConfigSpec.changeTrackingEnabled = $false
    $VMView.reconfigVM($VMConfigSpec)
    $Snapshot = New-Snapshot -VM $VM -Name "Disable CBT"
    $Snapshot | Remove-Snapshot -confirm:$false

    Write-Host "Enable CTK on $($VM.Name) is set to $((Get-VM -Name $VM.Name).ExtensionData.Config.ChangeTrackingEnabled)"
}
