# Get-ClusterVMInfo
# Creates 2 reports - 1 Host level report, 1 VM level report.
# Author: Adam Rush
# Created: 2017-02-12
<#
Connect-VIServer vCenterServer01
#>

# Vars
$VMNameIgnoreRegex = '^svm'

$Timestamp = (Get-Date -Format ("yyyy-MM-dd_HH-mm-ss"))
$OutputFolder = "$PSScriptRoot\ClusterVM-Info-Reports_$($Timestamp)\"

$HostReportPath = "$($OutputFolder)\Host-Report_$($Timestamp).csv"
$VMReportPath = "$($OutputFolder)\VM-Report_$($Timestamp).csv"

$HostReport = @()
$VMReport = @()

# Create Reports Output Folder if it doesnt exist
New-Item -Path $OutputFolder -ItemType directory -Force -ErrorAction Stop

Write-Host "Finding Clusters..." -ForegroundColor Yellow -NoNewline
$Clusters = Get-Cluster
Write-Host "$($Clusters.count) Clusters found." -ForegroundColor Green

foreach ($Cluster in ($Clusters)) {

    Write-Host "Processing Cluster [$($Cluster)]" -ForegroundColor Yellow

    Write-Host "Finding Hosts..." -ForegroundColor Yellow -NoNewline
    $VMHosts = $Cluster | Get-VMHost
    Write-Host "$($VMHosts.count) Hosts found." -ForegroundColor Green

    foreach ($VMHost in $VMHosts) {

        Write-Host "Processing Host [$($VMHost)]..." -ForegroundColor Cyan -NoNewline

        $VMs = $VMHost | Get-VM
        $HostReport += $VMHost | Select-Object @{N = 'Cluster'; E = { $_.Parent.Name }}, Name, ConnectionState, @{N = 'VMCount'; E = { ($VMs.count) }}

        Write-Host "$($VMs.count) VMs found." -ForegroundColor Green
        Write-Host "Processing VMs " -ForegroundColor Cyan -NoNewline

        foreach ($VM in $VMs) {

            Write-Host "." -ForegroundColor Cyan -NoNewline
            $VMReport += $VM | Select-Object @{N = ’Cluster’; E = { $_.VMHost.Parent.Name }},
            VMHost,
            @{N = 'VMName'; E = { $_.Name }},
            NumCpu,
            MemoryGB,
            @{N = 'DiskUsageGB'; E = { [math]::Round( ($_ | Get-HardDisk | measure-Object CapacityGB -Sum).sum ) }},
            PowerState,
            @{N = "ToolStatus"; E = { $_.ExtensionData.Guest.ToolsStatus }},
            @{N = "ToolsRunningStatus"; E = { $_.ExtensionData.Guest.ToolsRunningStatus }},
            @{N = "ToolsVersion"; E = { $_.ExtensionData.Guest.ToolsVersion }},
            @{N = 'SnapshotDateCreated'; E = { if ( $_.ExtensionData.Snapshot -ne $null ) { ($_ | Get-Snapshot | Select-Object -ExpandProperty Created) } }},
            @{N = 'SnapshotDescription'; E = { if ( $_.ExtensionData.Snapshot -ne $null ) { ($_ | Get-Snapshot | Select-Object -ExpandProperty Description) } }} | Where-Object { $_.VMName -notmatch $VMNameIgnoreRegex }
        }
        Write-Host "`n" -ForegroundColor Cyan
    }
}

$VMReportSorted = $VMReport | Sort-Object Cluster, VMHost, PowerState
$HostReportSorted = $HostReport | Sort-Object Cluster, Name

$VMReportSorted | Format-Table -AutoSize
$HostReportSorted | Format-Table -AutoSize

# Export CSVs
Write-Host "Exporting Host Report to [$($HostReportPath)]" -ForegroundColor Yellow
$HostReportSorted | Export-Csv -Path $HostReportPath -NoTypeInformation -UseCulture

Write-Host "Exporting VM Report to [$($VMReportPath)]" -ForegroundColor Yellow
$VMReportSorted | Export-Csv -Path $VMReportPath -NoTypeInformation -UseCulture
