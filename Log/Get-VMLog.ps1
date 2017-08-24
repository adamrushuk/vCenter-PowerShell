#requires -version 2
#requires -pssnapin VMware.VimAutomation.Core -version 4.1
function Get-VMLog{
    <#
    .SYNOPSIS
    Retrieve the virtual machine logs
    .DESCRIPTION
    The function retrieves the logs from one or more
    virtual machines and stores them in a local folder
    .NOTES
    Author:  Luc Dekens
    .PARAMETER VM
    The virtual machine(s) for which you want to retrieve
    the logs.
    .PARAMETER Path
    The folderpath where the virtual machines logs will be
    stored. The function creates a folder with the name of the
    virtual machine in the specified path.
    .EXAMPLE
    PS> Get-VMLog -VM $vm -Path "C:\VMLogs"
    .EXAMPLE
    PS> Get-VM | Get-VMLog -Path "C:\VMLogs"
    #>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [PSObject[]]$VM,
        [parameter(Mandatory=$true)]
        [string]$Path
    )
    process{
        foreach($obj in $VM){
            if($obj.GetType().Name -eq "string"){
                $obj = Get-VM -Name $obj
            }
        }
        $logPath = $obj.Extensiondata.Config.Files.LogDirectory
        $dsName = $logPath.Split(']')[0].Trim('[')
        $vmPath = $logPath.Split(']')[1].Trim(' ')
        $ds = Get-Datastore -Name $dsName
        $drvName = "MyDS" + (Get-Random)
        New-PSDrive -Location $ds -Name $drvName -PSProvider VimDatastore -Root '\' | Out-Null
        Copy-DatastoreItem -Item ($drvName + ":" + $vmPath + "*.log") -Destination ($Path + "\" + $obj.Name + "\") -Force:$true
        Remove-PSDrive -Name $drvName -Confirm:$false
    }
}