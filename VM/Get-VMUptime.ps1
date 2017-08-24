<#
Connect-VIServer vcenter01
#>
# Uptime / boot time
$LastBootProp = @{
    Name = 'LastBootTime'
    Expression = {
        ( Get-Date ) - ( New-TimeSpan -Seconds $_.Summary.QuickStats.UptimeSeconds )
    }
}

# Filters for powered on vms, and sorts boot time in descending order
$Report = Get-View -ViewType VirtualMachine -Filter @{"runtime.PowerState" = "poweredOn"} -Property Name, Summary.QuickStats.UptimeSeconds |
    Select-Object Name, $LastBootProp | Sort-Object -Descending -Property LastBootTime

$Report.Count
$Report

#######
# For Get-VM use:
$VMs = Get-VM
$PoweredOnVMs = $VMs | Where-Object { $_.PowerState -eq 'PoweredOn' }
$PoweredOnVMs | Select-Object Name, @{ n = 'Uptime'; e = { (Get-Date) - (New-TimeSpan -Seconds $_.ExtensionData.Summary.QuickStats.UptimeSeconds) } }
