Param(
        [switch]$noKeep,                # If we decide not to keep the history
        [int32]$History = 3,            # if -nokeep, just keep the last $History zipped files
        [int32]$DelayInSeconds=1200     # Delay in seconds of each Procmon
        
        )

$LogPath = "C:\CircularProcmon"
$ProcmonPath = $LogPath+"\Procmon.exe"
$ConfigFile = $LogPath+"\ProcmonConfiguration.pmc"

[int32]$MaxLogs = 5
[int32]$Counter = 0

do
{
    $Counter++

    # Reset counter if $MaxLogs is reached : This cause an infinite loop
    if($Counter -gt $MaxLogs){
        $Counter = 1
    }

    # Generate strings
    $Logfile = $LogPath+"\Logfile_"+$counter+".pml"
    $ProcMonParameters = "/Backingfile $Logfile /loadConfig $ConfigFile /AcceptEula /Minimized /Quiet"
  
    # Start ProcMon for $DelayInSecond seconds
    start-process -FilePath $ProcmonPath -ArgumentList $ProcMonParameters
    Start-Sleep -Seconds $DelayInSeconds

    # Terminate ProcMon
    start-process -FilePath $ProcmonPath -ArgumentList "/Terminate" -Wait
  
    # Compress log files and remove trace files
    $Date = Get-Date
    if ($Date.Month -lt 10){ $FormattedMonth = "0"+$Date.Month}else{$FormattedMonth = $Date.hour}
    if ($Date.Day -lt 10){ $FormattedDay = "0"+$Date.Day}else{$FormattedDay = $Date.Day}
    if ($Date.Hour -lt 10){ $FormattedHour = "0"+$Date.hour}else{$FormattedHour = $Date.hour}
    if ($Date.Minute -lt 10){ $FormattedMinute = "0"+$Date.Minute}else{$FormattedMinute = $Date.Minute}
    if ($Date.Second -lt 10){ $FormattedSecond = "0"+$Date.Second}else{$FormattedSecond = $Date.Second}

    $ZipPrefix = [string]$Date.Year+$FormattedMonth+$FormattedDay+"_"+[string]$FormattedHour+$FormattedMinute+$FormattedSecond
    $Zipfile = $LogPath+"\Logfile_"+$ZipPrefix+".zip"
    Write-Host "Compress $LogFile to $ZipFile"
    Start-Job -Name "Compress $Counter" -ArgumentList @($LogPath, $Logfile, $Zipfile){
        Param(
            [string]$LogPath, 
            [string]$LogFile,
            [string]$ZipFile)
        Compress-Archive -path $LogFile -DestinationPath $Zipfile
        Remove-Item $LogFile
    }

    # Purge history
    #   :::: Needs improvement
    if ($noKeep){
        $ZipHistory = Get-ChildItem -Path $LogPath -Filter "*.zip"
        if ($ZipHistory.count -gt $History){
            Get-Item $ZipHistory[0] | Remove-Item
        }
    }

}while ($Counter -le $MaxLogs)