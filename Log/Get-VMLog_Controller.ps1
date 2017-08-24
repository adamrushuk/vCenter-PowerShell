# Author: Adam Rush
# Get VM logs controller script

# Load main function
. '.\Get-VMLog.ps1'

# Vars
$VMNames = 'VM1', 'VM2'
$LogPath = 'VMLogs'

# Create Log folder if it doesnt exist
New-Item -Path $LogPath -ItemType directory -Force -ErrorAction Stop

# Get VMs
$VMs = Get-VM -Name $VMNames

# Get VM Logs
$VMs | Get-VMLog -Path $LogPath
