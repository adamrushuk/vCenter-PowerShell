<#
Author: Adam Rush
# Find all VM host locations for stretched cluster, filtering with certain IPs assigned to NICs
$vCenterName = 'vcenter01'
Connect-VIServer $vCenterName
#>
$FolderName = '123-456-1-abc123 '
$ExportPath = Join-Path -Path "$HOME\Desktop" -ChildPath 'VMHostLocation.csv'
$Folder = Get-Folder -Name $FolderName
$VMs = Get-VM -Location $Folder
$VMs.Count

# Get Location custom fields
$si = Get-View ServiceInstance
$caMgr = Get-View -Id $si.Content.customFieldsManager
$key = $caMgr.Field | Where-Object{$_.ManagedObjectType -eq 'HostSystem' -and $_.Name -eq 'Location'} |
    Select-Object -ExpandProperty Key

# Get VMs that start with "10.0."
$FilteredVMs = $VMs | Where-Object { $_.Guest.IPAddress -match '^10\.0\.' }
$FilteredVMs.Count

$Report = $FilteredVMs | Select-Object Name, VMHost,
    @{N='Location';E={$script:esx=Get-View -Id $_.VMHost.Id -Property Name,CustomValue; $script:esx.CustomValue | Where-Object{$_.Key -eq $key} | Select-Object -ExpandProperty Value}}

$Report | Export-Csv -Path $ExportPath -UseCulture -NoTypeInformation

# Get disk and datastore locations
$DiskReportPath = Join-Path -Path "$HOME\Desktop" -ChildPath 'DiskDatastores.csv'
$Disks = $VMs | Get-HardDisk
$Report = $Disks | Select-Object @{n='VMName';e={$_.Parent.Name}}, @{n='Datastore';e={ $_.Filename.Split('[')[1].Split(']')[0] }}, @{n='Filename';e={$_.Filename}}
$Report.Count
$Report | Export-Csv -Path $DiskReportPath -UseCulture -NoTypeInformation
