# Enable SSH and open PuTTY as root user
# Adam Rush
# Created: 2016-12-30

# Vars
$Hostname = 'ESXi01'
$vCenterName = 'vCenterServer01'

# Connect to vCenter
Connect-VIServer $vCenterName

# Enable SSH
Get-VMHost -Name $Hostname | ForEach-Object { Start-VMHostService -HostService ( $_ | Get-VMHostService | Where-Object { $_.Key -eq "TSM-SSH"} ) }

# Open PuTTY and login as root
$CMD = 'C:\Program Files (x86)\PuTTY\putty.exe'
$AllArgs = @('-l', 'root')
& $CMD $Hostname $AllArgs
