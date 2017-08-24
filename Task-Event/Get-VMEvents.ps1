<#
[DateTime]$StartTime = '2017-02-08 00:00'
[DateTime]$FinishTime = '2017-02-08 15:00'

$StartTime = (Get-Date).AddHours(-1)
$Events = Get-VIEvent -Start $StartTime
$Events

# Get VM Events for given time range
#>
$VMNames = 'VM1','VM2'
[DateTime]$StartTime = '2017-01-23 09:00'
[DateTime]$FinishTime = '2017-01-23 15:00'

$VMs = Get-VM -Name $VMNames

$Events = Get-VIEvent -Entity $VMs -Start $StartTime -Finish $FinishTime

Write-Host "$($Events.Count) events found for $VMNames"