function Get-VMClusterInfo {
    <#
    .SYNOPSIS
        Get Hosts that contain VMs with less vCPUs than specified
    .DESCRIPTION
        Get Hosts that contain VMs with less vCPUs than specified
    .EXAMPLE
        Get-VMClusterInfo -MinCpuCount 22
    .EXAMPLE
        Get-VMClusterInfo -MinCpuCount 22 -Name 'Cluster01'
    .EXAMPLE
        Get-VMClusterInfo -MinCpuCount 22 -Name 'Cluster01' -Path 'C:\Reports\'
    #>

    [CmdletBinding()]
    param (
        # Minimum CPU Count
        [Parameter(Mandatory = $true)]
        [int]
        $MinCpuCount,

        # Cluster name
        [string]
        $Name,

        # Path for CSV Export
        [string]
        $Path
    )

    # Report Vars
    $Timestamp = (Get-Date -Format ("yyyy-MM-dd_HH-mm-ss"))
    $OutputFolder = "$Path\VMClusterInfo-Reports_$($Timestamp)\"

    $HostsWithNoLargeCPUVMReportPath = "$($OutputFolder)\HostsWithNoLargeCPUVM-Report_$($Timestamp).csv"
    $HostReportPath = "$($OutputFolder)\Host-Report_$($Timestamp).csv"
    $VMReportPath = "$($OutputFolder)\VM-Report_$($Timestamp).csv"

    $HostsWithNoLargeCPUVMReport = @()
    $HostReport = @()
    $VMReport = @()

    # Was Report Path provided?
    if ($PSBoundParameters.ContainsKey("Path")) {
        # Create Reports Output Folder if it doesnt exist
        New-Item -Path $OutputFolder -ItemType directory -Force -ErrorAction Stop
    }

    # Was Cluster Name provided?
    if ($PSBoundParameters.ContainsKey("Name")) {

        $Clusters = Get-Cluster -Name $Name

    }
    else {

        $Clusters = Get-Cluster
    }

    # Get Cluster info
    foreach ($Cluster in $Clusters) {

        # Get Hosts
        Write-Host "`n`nGetting Cluster Info for [$($Cluster)]" -ForegroundColor Yellow
        Write-Host "Finding all Hosts..." -ForegroundColor Cyan -NoNewline
        $AllHosts = $Cluster | Get-VMHost
        $HostReport += $AllHosts
        $UnconnectedHosts = $AllHosts | Where-Object { $_.ConnectionState -ne 'Connected'}
        Write-Host "$($AllHosts.count) Hosts found ($($UnconnectedHosts.count) not currently in use)." -ForegroundColor Green

        # Get VMs
        Write-Host "Finding all VMs..." -ForegroundColor Cyan -NoNewline
        #$AllVMs = $Cluster | Get-VM | Select @{N='Cluster';E={$Cluster}}, *
        $AllVMs = $Cluster | Get-VM
        $VMReport += $AllVMs
        $PoweredOffVMs = $AllVMs | Where-Object { $_.PowerState -eq 'PoweredOff'}
        Write-Host "$($AllVMs.count) VMs found ($($AllVMs.count - $PoweredOffVMs.count) Powered On / $($PoweredOffVMs.count) Powered Off)." -ForegroundColor Green

        # Get VM with Min CPU Count
        Write-Host "$MinCpuCount CPU VM info ---" -ForegroundColor Yellow
        Write-Host "Finding VMs with $MinCpuCount or more CPU's..." -ForegroundColor Cyan -NoNewline
        $LargeCPUVMs = $AllVMs | Where-Object {$_.NumCpu -ge $MinCpuCount}
        $LargeCPUVMsPoweredOff = $LargeCPUVMs | Where-Object { $_.PowerState -eq 'PoweredOff'}
        Write-Host "$($LargeCPUVMs.count) VMs found ($($LargeCPUVMs.count - $LargeCPUVMsPoweredOff.count) Powered On / $($LargeCPUVMsPoweredOff.count) Powered Off)." -ForegroundColor Green

        # Check VM DRS Automation Level
        Write-Host "Checking VM DrsAutomationLevel is 'Manual' for $MinCpuCount+ CPU VM's..." -ForegroundColor Cyan -NoNewline
        $DRSNotManualVMs = $LargeCPUVMs | Where-Object {$_.DrsAutomationLevel -ne 'Manual'}
        $FGColour = 'Green'
        if ($($DRSNotManualVMs.count) -gt 0) {

            $FGColour = 'Red'
            Write-Host "$($DRSNotManualVMs.count) VMs found." -ForegroundColor $FGColour
            Write-Output $DRSNotManualVMs | Select-Object Name, DrsAutomationLevel, NumCpu, PowerState, VMHost, Cluster | Format-Table -AutoSize
        }
        Write-Host "$($DRSNotManualVMs.count) issues found." -ForegroundColor $FGColour

        # Check for multiple "Min CPU Count" VMs per host
        Write-Host "Finding Hosts with multiple $MinCpuCount+ CPU VM's..." -ForegroundColor Cyan -NoNewline
        $HostsWithTooManyLargeCPUVM = $LargeCPUVMs | Group-Object VMHost | Where-Object {$_.Count -gt 1} | Select-Object Name, @{N = 'LargeVMs'; E = { ($_.Group | ForEach-Object { $_.Name }) -join ', ' }}

        $FGColour = 'Green'
        if ($HostsWithTooManyLargeCPUVM -ne $null) { $FGColour = 'Red' }

        Write-Host "$(($HostsWithTooManyLargeCPUVM | Measure-Object).count) Hosts found." -ForegroundColor $FGColour
        Write-Output $HostsWithTooManyLargeCPUVM | Format-Table -AutoSize

        # Find hosts with no "Min CPU Count" VMs
        Write-Host "Finding Hosts with no $MinCpuCount+ CPU VM's present..." -ForegroundColor Cyan -NoNewline

        # Get unique array of hosts with "high CPU Count" VMs on them
        $HostsWithLargeCPUVM = $LargeCPUVMs | Select-Object VMHost
        $HostNamesWithLargeCPUVM = $HostsWithLargeCPUVM | Select-Object -ExpandProperty VMHost | Select-Object -ExpandProperty Name

        # Compare both arrays
        $HostsWithNoLargeCPUVM = $AllHosts | Where-Object { $_ -notin $HostNamesWithLargeCPUVM }

        $FGColour = 'Red'
        if ($($HostsWithNoLargeCPUVM.count) -gt 0) {
            $FGColour = 'Green'
            # Add to Report for output
            $HostsWithNoLargeCPUVMReport += $HostsWithNoLargeCPUVM
        }

        Write-Host "$($HostsWithNoLargeCPUVM.count) Hosts found." -ForegroundColor $FGColour

    }

    # Export report data if "-Path" is supplied
    if ($PSBoundParameters.ContainsKey("Path")) {

        Write-Host "`n`nSpare Hosts with no $MinCpuCount+ CPU VM's present..." -ForegroundColor Yellow
        Write-Output $HostsWithNoLargeCPUVMReport | Format-Table -GroupBy Parent -Property Name, PowerState, ConnectionState

        $HostsWithNoLargeCPUVMReport | Select-Object   @{N = 'Cluster'; E = { $_.Parent }}, Name, ConnectionState, PowerState, NumCpu, CpuTotalMhz,
            CpuUsageMhz, @{N = 'MemoryTotalGB'; E = { [math]::Round( $_.MemoryTotalGB ) }}, @{N = 'MemoryUsageGB'; E = { [math]::Round( $_.MemoryUsageGB ) }} |
            Export-Csv -Path $HostsWithNoLargeCPUVMReportPath -NoTypeInformation -UseCulture
    }

}
