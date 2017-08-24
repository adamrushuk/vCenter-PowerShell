$VMIDs = Get-Content -Path 'VM-IDs.txt'
Get-VM -id $VMIDs | Get-Snapshot | Remove-Snapshot
