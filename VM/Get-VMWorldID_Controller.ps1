# Load function
. '.\Get-VMWorldID.ps1'

$VMNames = @(
    'VM01'
)
Get-VMWorldID $VMNames
