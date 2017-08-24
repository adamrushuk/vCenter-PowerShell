# https://communities.vmware.com/message/2645075
$stat = 'datastore.totalReadLatency.average', 'datastore.totalWriteLatency.average'

$dsHash = @{}
Get-Datastore | Where-Object {$_.Type -eq 'VMFS' -and $_.ExtensionData.Summary.MultipleHostAccess} | ForEach-Object {
    $dsHash.Add($_.ExtensionData.Info.Url.Split('/')[-2], $_.Name)
}

$vm = Get-VM

Get-Stat -Entity $vm -Stat $stat -Realtime -MaxSamples 5 -ErrorAction SilentlyContinue |
    Group-Object -Property {$_.Entity.Name} | ForEach-Object {
    $obj = [ordered]@{
        VM = $_.Name
    }
    $dsHash.GetEnumerator() | Sort-Object -Property Value | ForEach-Object {
        $obj.Add("$($_.Value) Read Latency", 'na')
        $obj.Add("$($_.Value) Write Latency", 'na')
    }
    $_.Group | Group-Object -Property Instance | ForEach-Object {
        if ($dsHash.ContainsKey($_.Name)) {
            $obj."$($dsHash[$_.Name]) Read Latency" = $_.Group | Where-Object {$_.MetricId -eq 'datastore.totalReadLatency.average'} |
                Measure-Object -Property Value -Average | Select-Object -ExpandProperty Average
            $obj."$($dsHash[$_.Name]) Write Latency" = $_.Group | Where-Object {$_.MetricId -eq 'datastore.totalWriteLatency.average'} |
                Measure-Object -Property Value -Average | Select-Object -ExpandProperty Average
        }
    }
    New-Object PSObject -Property $obj
}