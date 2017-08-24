# Author: Adam Rush
# Created on: 2016-01-05
# Last updated on 2016-12-30
# Get all VMs in a ResourcePool, and list it's Host, Host Location, and Datastore of each disk including actual space used.

# Enter ResourcePool name. This can handle partial matching and return multiple ResourcePools
# $rpName = 'ResourcePool name'

# You can be more specific by entering the ResourcePool ID (found in brackets after the name) eg:
$rpName = 'Some Company (Tier01) (abcdef-asda-sd-asd-asd-as)'
$rpNameUUID = 'abcdef-asda-sd-asd-asd-as'

# Enter the path for the CSV export
$reportName = "$(Split-Path $script:MyInvocation.MyCommand.Path)\ResourcePool-VMs-Locations-Datastores_$($rpName).csv"

# Connect to stretched vCenter
Connect-VIServer VCENTER01

$si = Get-View ServiceInstance
$caMgr = Get-View -Id $si.Content.customFieldsManager
$key = $caMgr.Field | Where-Object {$_.ManagedObjectType -eq 'HostSystem' -and $_.Name -eq 'Location'} |
    Select-Object -ExpandProperty Key

$rp = Get-View -ViewType ResourcePool -Filter @{'Name' = "$rpNameUUID"}

$rp | ForEach-Object {Get-View -Id $_.VM} |
    Select-Object @{N = "ResourcePool"; E = {Get-View -Id $_.ResourcePool -Property Name | Select-Object -ExpandProperty Name}},
    Name,
    @{N = 'Location'; E = {$script:esx = Get-View -Id $_.Runtime.Host -Property Name, CustomValue; $script:esx.CustomValue | Where-Object {$_.Key -eq $key} | Select-Object -ExpandProperty Value}},
    @{N = 'Host'; E = {$script:esx | Select-Object -ExpandProperty Name}},
    @{N = 'Datastore'; E = {($_.Storage.PerDatastoreUsage | ForEach-Object {
                    "$(Get-View -Id $_.Datastore -Property Name | Select-Object -ExpandProperty Name) ($([math]::Round(($_.Committed/1GB),0))GB)"
                }) -join ', '}} | Export-Csv -Path $reportName -NoTypeInformation -UseCulture
