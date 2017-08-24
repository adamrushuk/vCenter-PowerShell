# Author: Adam Rush
# Created: 2017-01-18
# Modified: 2017-01-27 18:00

function Write-ScreenAndLog {
    <#
    .SYNOPSIS
        Writes messages to screen and log file.
    .DESCRIPTION
        Writes messages to screen and log file.
        Screen output uses Write-Verbose unless -Screen parameter is used, then Write-Host is used.
    .EXAMPLE
        Write-ScreenAndLog -Message "Starting Disk Copy script: $StartTime" -OutputPath $OutputPath
    .EXAMPLE
        Write-ScreenAndLog -Message "Starting Disk Copy script: $StartTime" -OutputPath $OutputPath -Screen
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Message,

        [parameter(Mandatory = $true)]
        [string]$OutputPath,

        [parameter(Mandatory = $false)]
        [switch]$Screen
    )

    if ($PSBoundParameters.ContainsKey("Screen")) {
        $Message | ForEach-Object {Write-Host $_ -ForegroundColor Yellow; Out-File -FilePath $OutputPath -InputObject $_ -Append}

    }
    else {
        $Message | ForEach-Object {Write-Verbose $_; Out-File -FilePath $OutputPath -InputObject $_ -Append}
    }
}


function Copy-VMDisks {
    <#
    .SYNOPSIS
        Copies source VM disks and overwrites destination VM disks.
    .DESCRIPTION
        Copies source VM disks and overwrites destination VM disks.
        Once the source and destination VMDK file configurations are compared (disk count and capacity),
        the destination VMDK files are deleted and replaced by the source VMDK files.
    .EXAMPLE
        Copy-VMDisks -SourceVMName "VM1" -DestinationVMName "VM2"

        Prompts to copy/overwrite each destination disk.
    .EXAMPLE
        Copy-VMDisks -SourceVMName "VM1" -DestinationVMName "VM2" -Confirm:$false

        Doesn't prompt to copy/overwrite destination disks.
    .EXAMPLE
        Copy-VMDisks -SourceVMName "VM1" -DestinationVMName "VM2" -Verbose

        Outputs verbose messages to console.
    .NOTES
        Author: Adam Rush
        Created: 2017-01-27
    #>

    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    [OutputType([String])]
    Param
    (
        # Source VM name
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {Get-VM -Name $SourceVMName})]
        [Alias("source")]
        [string] $SourceVMName,

        # Source VM name
        [Parameter(Mandatory = $true,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {Get-VM -Name $DestinationVMName})]
        [Alias("destination")]
        [string] $DestinationVMName
    )

    # Vars
    $StartTime = (Get-Date -Format ("yyyy-MM-dd_HH-mm-ss"))
    $OutputFolder = "$(Split-Path $script:MyInvocation.MyCommand.Path)"
    $OutputPath = "$($OutputFolder)\Copy-VMDisks-Transcript_$($StartTime).log"

    # Display VM info
    Write-ScreenAndLog -Message "Starting Disk Copy script: $StartTime" -OutputPath $OutputPath -Screen
    Write-ScreenAndLog -Message "`nFinding Source and Destination VMs..." -OutputPath $OutputPath -Screen
    Write-ScreenAndLog -Message "Source VM: $SourceVMName" -OutputPath $OutputPath -Screen
    Write-ScreenAndLog -Message "Destination VM: $DestinationVMName" -OutputPath $OutputPath -Screen

    # Get VMs
    $SourceVM = Get-VM -Name $SourceVMName -ErrorAction Stop
    $DestinationVM = Get-VM -Name $DestinationVMName -ErrorAction Stop

    Write-ScreenAndLog -Message "$($SourceVM.Name) Provisioned Space GB: $([math]::Round( $SourceVM.ProvisionedSpaceGB, 2))GB, Used Space GB: $([math]::Round( $SourceVM.UsedSpaceGB, 2))GB" -OutputPath $OutputPath
    Write-ScreenAndLog -Message "$($DestinationVM.Name) Provisioned Space GB: $([math]::Round( $DestinationVM.ProvisionedSpaceGB, 2))GB, Used Space GB: $([math]::Round( $DestinationVM.UsedSpaceGB, 2))GB" -OutputPath $OutputPath

    # Check VMs are powered off
    if ($SourceVM.PowerState -ne "PoweredOff" -or $DestinationVM.PowerState -ne "PoweredOff") {
        throw "Both VMs must be powered off to continue. Exiting script..."
    }

    # Get disk info for comparison
    $SourceVMDisks = $SourceVM| Get-HardDisk | Select-Object Name, CapacityGB
    $DestinationVMDisks = $DestinationVM | Get-HardDisk | Select-Object Name, CapacityGB
    $Diff = Compare-Object -ReferenceObject $SourceVMDisks -DifferenceObject $DestinationVMDisks -Property Name, CapacityGB

    # Display VM Disk info
    Write-ScreenAndLog -Message "`nSourceVMDisks:" -OutputPath $OutputPath
    Write-ScreenAndLog -Message $SourceVMDisks -OutputPath $OutputPath
    Write-ScreenAndLog -Message "`nDestinationVMDisks: $DestinationVMDisks" -OutputPath $OutputPath
    Write-ScreenAndLog -Message $DestinationVMDisks -OutputPath $OutputPath

    if ($Diff.Count -gt 0) {

        Write-Warning "Source and Destination disk configuration DOES NOT match. Aborting script..."
        $Diff

        $FinishTime = (Get-Date -Format ("yyyy-MM-dd HH:mm:ss"))
        Write-ScreenAndLog -Message "Finished Disk Copy script: $FinishTime" -OutputPath $OutputPath

        return

    }
    else {

        Write-ScreenAndLog -Message "Source and Destination disk configurations match." -OutputPath $OutputPath -Screen

    }

    # Get all disks
    $DisksNames = $DestinationVM | Get-HardDisk | Select-Object -ExpandProperty Name

    $Tasks = @()
    $TaskStates = @()

    # Loop through disks and copy to destination path
    foreach ($DiskName in $DisksNames) {

        # Get disks
        $SourceDisk = $SourceVM | Get-HardDisk | Where-Object {$_.Name -eq "$DiskName"}
        $DestDiskPath = $DestinationVM | Get-HardDisk | Where-Object {$_.Name -eq "$DiskName"} | Select-Object -ExpandProperty Filename

        Write-ScreenAndLog -Message "Source path for $DiskName is $($SourceDisk.Filename)..." -OutputPath $OutputPath
        Write-ScreenAndLog -Message "Destination path for $DiskName is $($DestDiskPath)...`n" -OutputPath $OutputPath
        Write-ScreenAndLog -Message "Copy Task request for $($DiskName) Start Time: $(Get-Date -Format ("yyyy-MM-dd HH:mm:ss"))..." -OutputPath $OutputPath -Screen

        # Request disk copy tasks
        if ($pscmdlet.ShouldProcess($DestDiskPath, "Overwrite destination disk for $DestinationVMName")) {
            $Tasks += $SourceDisk | Copy-HardDisk -DestinationPath $DestDiskPath -Force -RunAsync
            Start-Sleep 10
        }

        Write-ScreenAndLog -Message "Copy Task request for $($DiskName) Completed Time: $(Get-Date -Format ("yyyy-MM-dd HH:mm:ss"))..." -OutputPath $OutputPath -Screen
    }

    # Get initial task states and provide first log update
    $TaskStates = $Tasks | Select-Object -ExpandProperty state

    # Output task progress to screen and log
    $Timestamp = (Get-Date -Format ("yyyy-MM-dd HH:mm:ss"))
    Write-Host $Timestamp

    $Tasks | Select-Object Name, State, PercentComplete, StartTime, FinishTime
    $Timestamp | Out-File -FilePath $OutputPath -Append
    $Tasks | Out-File -FilePath $OutputPath -Append


    # Update log file whilst tasks still in "running" state
    while ($TaskStates -contains "Running") {

        $TaskStates = $Tasks | Select-Object -ExpandProperty state

        # Output task progress to screen and log
        $Timestamp = (Get-Date -Format ("yyyy-MM-dd HH:mm:ss"))
        Write-Host $Timestamp

        $Tasks | Select-Object Name, State, PercentComplete, StartTime, FinishTime
        $Timestamp | Out-File -FilePath $OutputPath -Append
        $Tasks | Out-File -FilePath $OutputPath -Append

        Start-Sleep 120
    }

    $FinishTime = (Get-Date -Format ("yyyy-MM-dd HH:mm:ss"))
    Write-ScreenAndLog -Message "Finished Disk Copy script: $FinishTime"  -OutputPath $OutputPath -Screen
}
