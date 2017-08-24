# Format example: '[DS] vm/vm.vmdk'
$VMDKPaths = @(
    '[san04:DSC02_03] VM01 (f4c0327f-b93e-41ce-8eeb-49e9342588ef)/VM01 (f4c0327f-b93e-41ce-8eeb-49e9342588ef).vmdk'
    '[san04:DSC02_18] VM02 (1938cca7-9a6d-408b-8ba3-ab155280a7ec)/VM02 (1938cca7-9a6d-408b-8ba3-ab155280a7ec)_1.vmdk'
    '[san08:DSC05_06] VM03/VM03_1.vmdk'
)

$VMWithAttachedVMDKs = Get-View -ViewType VirtualMachine -Property Name, Config.Hardware.Device |
    Where-Object { $_.Config.Hardware.Device | Where-Object{ $_ -is [VMware.Vim.VirtualDisk] -and $_.Backing.Filename -in $VMDKPaths } }
