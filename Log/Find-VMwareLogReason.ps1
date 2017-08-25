# https://communities.vmware.com/message/2580831#2580831
$stopLines = @{
    'CPU reset: soft'                                                              = 'Guest OS initiated reset'
    'PIIX4: PM Soft Off.  Good-bye.'                                               = 'Guest OS initiated halt'
    'CPU reset: hard'                                                              = 'User or API initiated request to reset'
    'MKS local poweroff'                                                           = 'User or API initiated request to power off'
    'I120: Tools: sending ''OS_Halt'' (state = 1) state change request'            = 'User or API initiated request to shutdown'
    'I120: Tools: sending ''OS_Reboot'' (state = 2) state change request'          = 'User or API initiated request to restart'
    'Unexpected signal:'                                                           = 'Virtual machine reported a backtrace'
    'A problem has been detected and Windows has been shut down to prevent damage' = 'Virtual machine operating system had a system fault'
    'VMAutomation_Reset. Trying hard reset'                                        = 'Virtual machine was restarted by High Availability Virtual Machine Monitoring'
}

foreach ($vm in Get-VM) {
    $vmxPath = $vm.ExtensionData.Config.Files.VmpathName
    $dsObj = Get-Datastore -Name $vmxPath.Split(']')[0].TrimStart('[')
    New-PSDrive -Location $dsObj -Name DS -PSProvider VimDatastore -Root "\" | Out-Null
    $tempFile = [System.IO.Path]::GetTempFileName()
    Copy-DatastoreItem -Item "DS:\$($vm.Name)\vmware.log" -Destination $tempFile

    $log = Get-Content -Path $tempFile
    $esxLine = $log | Where-Object {$_ -match 'Hostname='}
    $esx = $esxLine.Split('=')[1]

    $reason = $log | Where-Object {$_ -match ($stopLines.Keys -join '|')} | ForEach-Object {
        $line = $_
        $stopLines.GetEnumerator() | Where-Object {$line -match $_.Name} | Select-Object -ExpandProperty Value
    }
    New-Object PSObject -Property @{
        VM     = $vm.Name
        ESXi   = $esx
        Reason = $reason
        Time   = Get-date $line.Split('|')[0] -Format "yyyyMMdd HH:mm"
    }

    Remove-Item -Path $tempFile -Confirm:$false
    Remove-PSDrive -Name DS -Confirm:$false
}
