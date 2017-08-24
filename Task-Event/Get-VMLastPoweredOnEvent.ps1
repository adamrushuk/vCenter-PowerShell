function Get-VMLastPoweredOnEvent {
    <#
        .SYNOPSIS
        Returns a hashtable of VMs and their last powered on event.

        .DESCRIPTION
        Returns a hashtable of VMs and their last powered on event.
        The key is the VM name, and the value is the datetime of the powered on event.
        Purposely doesnt use pipeline to be more efficient passing to Get-VIEvent.

        .PARAMETER Entity
        The VMs to find events for.

        .INPUTS
        VIObject

        .OUTPUTS
        System.Collections.Hashtable

        .EXAMPLE
        Get-VMLastPoweredOnEvent -Entity $VMs

        Searches all events for the given VMs.

        .EXAMPLE
        $StartDate = (Get-Date).AddDays(-30)
        Get-VMLastPoweredOnEvent -Entity $VMs -Start $StartDate

        Searches events within last 30 days for the given VMs.

        .NOTES
        Author: Adam Rush
    #>
    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $Entity,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [DateTime]
        $Start
    )

    Begin {}

    Process {

        try {

            $Now = Get-Date
            Write-Verbose "Started script at: $Now"
            Write-Verbose "$($Entity.Count) objects provided."

            # Set base parameters for Get-VIEvents
            $EventParams = @{
                Entity     = $Entity
                MaxSamples = ([int]::MaxValue)
            }

            # Use Start parameter if it exists
            if ($PSBoundParameters.ContainsKey('Start')) {
                $EventParams.Start = $Start
            }
            Write-Verbose "Event search parameters: $($EventParams | Out-String)"

            # Get Events
            $Events = Get-VIEvent @EventParams
            Write-Verbose "$($Events.Count) events found for $($Entity.Count) VMs"

            # Get all Event Types
            $EventTypes = $Events | Select-Object @{ n = 'Type'; e = {$_.GetType().Name}  }

            # Group Event Types and sort by count
            $EventTypesGrouped = $EventTypes | Group-Object Type
            Write-Verbose "$($EventTypesGrouped.Count) event types found"

            # Only get PowerOn Events, grouping by VM name
            $EventGrouped = $Events | Where-Object {$_ -is [VMware.Vim.VmPoweredOnEvent]} | Group-Object -Property {$_.Vm.Name}
            Write-Verbose "$($EventGrouped.Count) PowerOn events found for $($Entity.Count) VMs"

            # Get last power on event per VM
            $Report = $EventGrouped | Select-Object Name,
            @{N = 'LastPowerOn'; E = { ($_.Group | Sort-Object -Property CreatedTime -Descending | Select-Object -First 1 -ExpandProperty CreatedTime)}}
            Write-Verbose "$($Report.Count) Entries found for $($Entity.Count) VMs"

            # Create hashtable
            $LastPowerOnHash = @{}
            $Report | ForEach-Object { $LastPowerOnHash[$_.Name] = $_.LastPowerOn }
            Write-Verbose "PoweredOn events found for $($LastPowerOnHash.Count) VMs"
            Write-Output $LastPowerOnHash

            # Display time taken
            $FinishTime = Get-Date
            $Duration = New-TimeSpan -Start $Now -End $FinishTime
            Write-Verbose "Script completed in: $($Duration.Minutes)m$($Duration.Seconds)s"

        }
        catch [exception] {

            throw $_

        }

    } # End process

} # End function
