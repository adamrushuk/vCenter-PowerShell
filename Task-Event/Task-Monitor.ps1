# Path for the transcript
$Timestamp = (Get-Date -Format ("yyyy-MM-dd_HH-mm-ss"))
$OutputFolder = "$(Split-Path $script:MyInvocation.MyCommand.Path)"
$OutputPath = "$($OutputFolder)\Task-Monitor-Transcript_$($timestamp).log"

while ($TaskStatus = Get-Task -Id "Task-task-3479348") {
    $TaskStatus | Out-File -FilePath $OutputPath -Append
    Start-Sleep 120
}
