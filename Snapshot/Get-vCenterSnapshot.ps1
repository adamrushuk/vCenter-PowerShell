function Get-vCenterSnapshot {
    <#
    .SYNOPSIS
        Find all VM snapshots across multiple vCenter servers.
    .DESCRIPTION
        Find all VM snapshots across multiple vCenter servers, including creation source.
        Exports to a CSV file.
    .PARAMETER Server
        vCenter Server(s) to connect.
    .PARAMETER SourceType
        Snapshot type to filter creation source: Backup (eg. Avamar), User: (eg. vCloud User).
    .INPUTS
        System.String
    .OUTPUTS
        System.Management.Automation.PSObject
    .EXAMPLE
        Get-vCenterSnapshot -Server 'vcenter01','vcenter02'

        Finds all VM snapshots within vcenter01 and vcenter02.
    .EXAMPLE
        Get-vCenterSnapshot -Server 'vcenter01','vcenter02' -SourceType Backup

        Finds all VM snapshots within vcenter01 and vcenter02, where the snapshot was created by a Backup Application.
    .NOTES
        Author: Adam Rush
        Created: 2017-02-16
    #>

    [CmdletBinding(DefaultParameterSetName="Standard")]
    [OutputType('System.Management.Automation.PSCustomObject')]

    Param (
        # vCenter Server name(s)
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Server,

        # Snapshot Source Type
        [Parameter(Mandatory=$false)]
        [ValidateSet('Backup', 'User')]
        [String]
        $SourceType
    )

    Begin {
        Write-Verbose "Finding Snapshots in $($Server.count) vCenters"
    }
    Process {

        foreach ($vCenter in $Server) {

            # Connect to vCenter
            Write-Verbose "`nLogging in to $($vCenter)..."
            $null = Connect-VIServer $vCenter -ErrorAction Stop

            # Find snapshots
            Write-Verbose "Finding all snapshots in $($vCenter)..."
            $Snapshots = Get-View -Server $vCenter -ViewType VirtualMachine -Property Name, Snapshot -Filter @{ 'Snapshot' = '' } |
                ForEach-Object { Get-VM -Server $vCenter -Id $_.MoRef | Get-Snapshot }

            # Output to pipeline
            foreach ($Snapshot in $Snapshots) {

                $OrgFolder = if ( $Snapshot.VM.Folder.Parent.Parent.Name -ne $null ) { $Snapshot.VM.Folder.Parent.Parent.Name.Split(' (')[0] } else { "VCENTER" }
                $OrgVDCFolder = if ( $Snapshot.VM.Folder.Parent.Name -ne $null ) { $Snapshot.VM.Folder.Parent.Name } else { "VCENTER" }
                $vAppFolder = if ( $Snapshot.VM.Folder.Name -ne $null ) { $Snapshot.VM.Folder.Name } else { "VCENTER" }

                [PSCustomObject] @{
                    vCenter = $vCenter
                    Created = $Snapshot.Created
                    Org = $OrgFolder
                    OrgName = 'VCENTER'
                    OrgVDC = $OrgVDCFolder
                    vApp = $vAppFolder
                    VM = $Snapshot.VM
                    VMId = $Snapshot.VMId
                    PowerState = $Snapshot.PowerState
                    SizeGB = [math]::Round( $Snapshot.SizeGB, 2)
                    Name = $Snapshot.Name
                    Description = $Snapshot.Description
                }

            }

            # Disconnect from vCenter
            Write-Host "Logging out of $($vCenter)..."
            $null = Disconnect-VIServer $vCenter -Confirm:$false

        }

    }
    End {
        Write-Verbose "No more snapshots found. Processing complete."
    }
}
