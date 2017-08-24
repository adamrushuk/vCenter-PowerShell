# Finds all VMs (including Org, Org VDC, and vApp details) in the Datastores listed in datastores.txt then exports CSV file to Desktop
# Author: Adam Rush
# Created on: 2016-06-03

# Vars
$vCenter = "vCenterServer01"
$DatastoreClusterName = "DatastoreCluster_02"

Write-Host -ForegroundColor Yellow "Connecting to vCenter..."
Connect-VIServer $vCenter

# Check for vcloud connection (User property sometimes clears when intermittent issues, so worth checking)
Try {
    # Connect to vCloud
    if ($global:DefaultCIServers -eq $null -or $global:DefaultCIServers.IsConnected -match "false") {
        Write-Host "Connecting to vCloud..."
        $null = Connect-CIserver vcloud
    }
}
Catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $Error[0].InvocationInfo.PositionMessage -ForegroundColor Red
    exit
}

$timestamp = (Get-Date -Format ("yyyy-MM-dd_HH-mm-ss"))
$reportFolder = "$HOME\Desktop\Datastore-VMs"
$reportCSV = "$reportFolder\Datastore-VMs_$($vCenter)_$($DatastoreClusterName)_$($timestamp).csv"

# Create save path if it does not exist
if (!(Test-Path -Path $reportFolder)) {
    $null = New-Item -ItemType Directory -Force -Path $reportFolder
}

# Build a hash table for Org IDs and values are the Org Name's
Write-Host -ForegroundColor Yellow "Building vCloud Org lookup table..."
$orgNames = [ordered]@{}
$Orgs = search-cloud -querytype organization
$Orgs | ForEach-Object { $orgNames[$_.Name] = $_.DisplayName }
Write-Host -ForegroundColor Yellow "$($Orgs.count) Orgs found."

$report = @()

$datastores = Get-Content -Path datastores.txt
Write-Host -ForegroundColor Yellow "Getting datastores..."
<#
# Alternatively get all datastores
$DatastoreCluster = Get-DatastoreCluster -Name $DatastoreClusterName
$datastores = $DatastoreCluster | Get-Datastore
#>
foreach ($datastore in $datastores) {
    Write-Host -ForegroundColor Yellow "Getting VMs for [$($datastore.Name)]..."

    $vms = Get-Datastore $datastore | Get-VM |
        Select-Object @{N = 'Datastore'; E = {$datastore}},
    @{N = 'Org'; E = {[string]$script:orgID = $_.Folder.Parent.Parent.Name.Split('(')[0]; $script:orgID}},
    @{N = 'OrgName'; E = { $orgNames[$script:orgID.Trim()] }},
    @{N = 'Org VDC'; E = {$_.Folder.Parent.Name.Split('(')[0]}},
    @{N = 'vApp'; E = {$_.Folder.Name.Split('(')[0]}},
    @{N = 'VM'; E = {$_.Name}} |
        Sort-Object Datastore, Org, "Org VDC", vApp, VM
    $report += $vms
}

Write-Host -ForegroundColor Yellow "Exporting to [$($reportCSV)]..."
$report | Export-Csv -Path $reportCSV -NoTypeInformation -UseCulture
