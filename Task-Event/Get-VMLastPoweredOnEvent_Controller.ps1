Set-StrictMode -Version Latest

# load Get-VMLastPoweredOnEvent
. '.\Get-VMLastPoweredOnEvent.ps1'

<#
Connect-VIServer vCenterServer01
#>
# Use NumberOfDays = -1 to find all events available (this may take a while)
$NumberOfDays = -1
$Now = Get-Date

Write-Host "NumberOfDays: $NumberOfDays (-1 finds all available events)" -ForegroundColor Cyan

# Get powered on VMs
$PoweredOnVMs = Get-VM | Where-Object {$_.PowerState -eq 'PoweredOn'}
Write-Host "$($PoweredOnVMs.Count) Powered On VMs found" -ForegroundColor Cyan

# Create hashtable for future lookups
$LastPowerOnHash = Get-VMLastPoweredOnEvent -Entity $PoweredOnVMs

# Merge data
$MergedReport = $PoweredOnVMs | Select-Object *, @{ n='LastPowerOn';e={$LastPowerOnHash[$_.Name]} }
$MergedReport.Count
$MergedReport | Select-Object -First 20 Name, LastPowerOn

# Display time taken
$FinishTime = Get-Date
$Duration = New-TimeSpan -Start $Now -End $FinishTime
Write-Host "Script completed in: $($Duration.Minutes)m$($Duration.Seconds)s" -ForegroundColor Yellow
