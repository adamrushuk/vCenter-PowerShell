# Author: Adam Rush
# Vars
$vCenter = 'vcenter01'
$ArrVMs = @(
    'VM1'
    'VM2'
    'VM3'
)

# Use empty strings for realtime stats
$StartDate = $null
$FinishDate = $null

# Connect to vCenter
Connect-VIServer $vCenter -ErrorAction Stop

# Path for the CSV export
$Timestamp = (Get-Date -Format ("yyyy-MM-dd_HH-mm-ss"))
$ReportFolder = "$(Split-Path $script:MyInvocation.MyCommand.Path)\VM-Perf-Stats"
$ReportPath = "$($ReportFolder)\VM-Perf-Stats_$($timestamp).csv"

# Create save path if it does not exist
if (!(Test-Path -Path $ReportFolder)) {
    $null = New-Item -ItemType Directory -Force -Path $ReportFolder
}

$VMs = Get-VM -Name $ArrVMs

$Stats = 'cpu.costop.summation', 'cpu.usagemhz.average', 'cpu.demand.average',
    'mem.active.average', 'mem.vmmemctl.average', 'mem.swapped.average',
    'datastore.totalReadLatency.average', 'datastore.totalWriteLatency.average', 'datastore.read.average',
    'datastore.write.average', 'net.usage.average', 'net.droppedRx.summation', 'net.droppedTx.summation'

# Build stat parameters
$StatParams = @{
    Stat        = $Stats
    ErrorAction = 'SilentlyContinue'
}
Write-Host "StatParams: $( $StatParams | Out-String)" -ForegroundColor Cyan
if (-not [string]::IsNullOrWhiteSpace($StartDate)) {
    $StatParams.Start = $StartDate
}
if (-not [string]::IsNullOrWhiteSpace($FinishDate)) {
    $StatParams.Finish = $FinishDate
}

if ( ([string]::IsNullOrWhiteSpace($StartDate)) -and ([string]::IsNullOrWhiteSpace($FinishDate)) ) {
    $StatParams.Realtime = $true
}

$Report = @()

foreach ($VM in $VMs) {

    # Add to stat parameters
    $StatParams.Entity = $VM

    Write-Host "StatParams: $( $StatParams | Out-String)" -ForegroundColor Cyan

    # Gather stats
    $StatResults = Get-Stat @StatParams

    $Groups = $StatResults | Group-Object -Property {$_.MetricId}
    $Row = $Groups | ForEach-Object {
        New-Object PSObject -Property @{
            Description  = $_.Group[0].Description
            Entity       = $_.Group[0].Entity
            EntityId     = $_.Group[0].EntityId
            Instance     = $_.Group[0].Instance
            MetricId     = $_.Group[0].MetricId
            Unit         = $_.Group[0].Unit
            IntervalSecs = $_.Group[0].IntervalSecs
            Minimum      = [math]::Round( ($_.Group | Where-Object { if ($_.MetricId -match "datastore") {$_.instance -ne ""} else {$_.instance -eq ""} } | Measure-Object -Property Value -Minimum).Minimum, 2)
            Maximum      = [math]::Round( ($_.Group | Where-Object { if ($_.MetricId -match "datastore") {$_.instance -ne ""} else {$_.instance -eq ""} } | Measure-Object -Property Value -Maximum).Maximum, 2)
            Average      = [math]::Round( ($_.Group | Where-Object { if ($_.MetricId -match "datastore") {$_.instance -ne ""} else {$_.instance -eq ""} } | Measure-Object -Property Value -Average).Average, 2)
        }
    }

    $Report += $Row | Select-Object entity, metricid, unit, minimum, maximum, average
}

Write-Host -ForegroundColor Yellow "Exporting to [$($ReportPath)]..."
$Report | Export-Csv -Path $ReportPath -NoTypeInformation -UseCulture

Disconnect-VIServer $vCenter -Confirm:$false
