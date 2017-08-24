# Load function
. '.\Get-vCenterSnapshot.ps1'

$vCenters = @(
    'vCenterServer01'
    'vCenterServer02'
)

# Vars
$CSVReportFolder = 'C:\Reports'
$CSVPath = "$CSVReportFolder\vCenter-Snapshots.csv"
$StartTime = (Get-Date)

Write-Host "Script started at: $StartTime" -ForegroundColor Yellow

# Check report path
$null = New-Item -Path $CSVReportFolder -ItemType directory -Force -ErrorAction Stop

# Find snapshots
Write-Host "Finding Snapshots in $($vCenters.count) vCenters" -ForegroundColor Yellow
Write-Output $vCenters
$Snaps = Get-vCenterSnapshot -Server $vCenters

# Display snapshot info
Write-Host "$($Snaps.Count) snapshots found." -ForegroundColor Yellow
$Snaps | Group-Object -Property vCenter | Select-Object Count, Name | Format-Table -AutoSize
$Snaps | Group-Object -Property Description | Select-Object Count, Name | Sort-Object Count -Descending | Select-Object -First 10 | Format-Table -AutoSize

# Export Snapshots
Write-Host "Exporting snapshot results to [$CSVPath]..." -ForegroundColor Green
$Snaps | Export-Csv -Path $CSVPath -NoTypeInformation -UseCulture

# Display script duration
$FinishTime = (Get-Date)
$Duration = New-TimeSpan -Start $StartTime -End $FinishTime
Write-Host "Script finished at: $FinishTime" -ForegroundColor Yellow
Write-Host "Script duration: $($Duration.Minutes)m$($Duration.Seconds)s" -ForegroundColor Yellow
