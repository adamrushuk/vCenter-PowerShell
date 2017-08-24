function Get-VMWorldID {
    <#
    .SYNOPSIS
        Finds the World ID for VM processes across all hosts in multiple clusters.
    .DESCRIPTION
        Finds the World ID for VM processes across all hosts in multiple clusters,
        and optionally kills them.
    .EXAMPLE
        Get-VMWorldID -VMNames 'VM1'

        Displays the World ID for VM1 processes, and what host(s) they are running on.
    .EXAMPLE
        Get-VMWorldID -VMNames 'VM1','VM2'

        Displays the World ID for VM1 and VM2 processes, and what host(s) they are running on.
    .EXAMPLE
        $VMNames = @(
            'VM1'
            'VM2'
            'VM3'
        )
        Get-VMWorldID -VMNames $VMNames

        Displays the World ID for VM1, VM2, and VM3 processes, and what host(s) they are running on.
    .EXAMPLE
        Get-VMWorldID -VMNames'VM1' -Kill

        Displays the World ID for VM1 processes, what host(s) they are running on, then kills the process.
    .NOTES
        Author: Adam Rush
        Created: 2017-02-09
    #>

    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    Param(
        [parameter(Mandatory = $true)]
        [string[]]$VMNames,

        [switch]$Kill
    )

    Write-Verbose "Finding hosts..."
    $VMHosts = (Get-Cluster | Get-VMHost)

    Write-Verbose "Found $($VMHosts.count) hosts..."
    Write-Verbose "Target VMs are: $($VMNames -join ',')"

    foreach ($VMHost in $VMHosts) {

        Write-Host "Searching Host: $($VMHost)" -ForegroundColor Yellow
        $EsxCli = $VMHost | Get-EsxCli

        Write-Verbose "Finding VM processes..."
        $Processes = $EsxCli.vm.process.list() | Where-Object {$_.DisplayName -in $VMNames}

        if ($Processes.count -gt 0) {

            Write-Host "$($Processes.count) processes found..." -ForegroundColor Green
            Write-Verbose "($Processes | Out-String)`n"

            foreach ($Process in $Processes) {

                Write-Host "VM: $($Process.DisplayName)" -ForegroundColor Cyan
                Write-Host "World ID: $($Process.WorldID)`n" -ForegroundColor Cyan

                if ($PSBoundParameters.ContainsKey("Kill")) {

                    if ($pscmdlet.ShouldProcess($Process.DisplayName, "Kill World ID '$($Process.WorldID)'")) {

                        # Kill WorldID
                        Write-Host "Killing World ID '$($Process.WorldID)' for $($Process.DisplayName)..." -ForegroundColor Yellow
                        $EsxCli.vm.process.kill("hard", $Process.WorldID)
                    }
                }

            } # end foreach Processes

        }
        else {

            Write-Host "$($Processes.count) processes found...`n" -ForegroundColor Red
        }

    } # end foreach VMHosts

} # end function Get-VMWorldID
