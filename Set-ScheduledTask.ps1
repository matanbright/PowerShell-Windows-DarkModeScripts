[CmdletBinding()]
param (
    [System.Nullable[System.DateTime]] $DarkModeStartTime,
    [System.Nullable[System.DateTime]] $DarkModeEndTime,
    [System.Nullable[System.DateTime]] $NightLightStartTime,
    [System.Nullable[System.DateTime]] $NightLightEndTime
)


$SILENT_RUNNER_EXECUTABLE_NAME = "SilentRunner.exe"
$SCHEDULED_SCRIPT_NAME = "Set-DarkModeAndNightLightStates.ps1"


$scheduledTaskName = "SetDarkModeAndNightLightStates ($([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value))"
if (($null -eq $DarkModeStartTime) -and ($null -eq $DarkModeEndTime) -and ($null -eq $NightLightStartTime) -and ($null -eq $NightLightEndTime)) {
    Write-Host -NoNewline "No arguments were provided, so, would you want to remove the scheduled task? [Y/N]: "
    if ((Read-Host) -eq "Y") {
        schtasks /Delete /TN $scheduledTaskName /F
        return
    }
}
$scheduledTaskTimes = @()
$scheduledTaskCommand = "`"" + $pwd.Path + "\" + $SILENT_RUNNER_EXECUTABLE_NAME + "`""
$scheduledTaskArguments = "powershell `".\$SCHEDULED_SCRIPT_NAME"
if (($null -ne $DarkModeStartTime) -and ($null -ne $DarkModeEndTime)) {
    $scheduledTaskTimes += $DarkModeStartTime
    $scheduledTaskArguments += " -DarkModeStartTime $($DarkModeStartTime.ToString("HH:mm"))"
    if ($scheduledTaskTimes -notcontains $DarkModeEndTime) {
        $scheduledTaskTimes += $DarkModeEndTime
    }
    $scheduledTaskArguments += " -DarkModeEndTime $($DarkModeEndTime.ToString("HH:mm"))"
} elseif (($null -ne $DarkModeStartTime) -xor ($null -ne $DarkModeEndTime)) {
    Write-Host "Warning: Dark mode's time was ignored because a start/end time was not specified!"
}
if (($null -ne $NightLightStartTime) -and ($null -ne $NightLightEndTime)) {
    if ($scheduledTaskTimes -notcontains $NightLightStartTime) {
        $scheduledTaskTimes += $NightLightStartTime
    }
    $scheduledTaskArguments += " -NightLightStartTime $($NightLightStartTime.ToString("HH:mm"))"
    if ($scheduledTaskTimes -notcontains $NightLightEndTime) {
        $scheduledTaskTimes += $NightLightEndTime
    }
    $scheduledTaskArguments += " -NightLightEndTime $($NightLightEndTime.ToString("HH:mm"))"
} elseif (($null -ne $NightLightStartTime) -xor ($null -ne $NightLightEndTime)) {
    Write-Host "Warning: Night light's time was ignored because a start/end time was not specified!"
}
$scheduledTaskArguments += "`""
$scheduledTaskXmlRepresentation = "
    <Task version=`"1.2`" xmlns=`"http://schemas.microsoft.com/windows/2004/02/mit/task`">
        <Principals>
            <Principal id=`"Author`">
                <UserId>$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)</UserId>
                <LogonType>InteractiveToken</LogonType>
                <RunLevel>LeastPrivilege</RunLevel>
            </Principal>
        </Principals>
        <Settings>
            <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
            <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
            <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
            <AllowHardTerminate>true</AllowHardTerminate>
            <StartWhenAvailable>true</StartWhenAvailable>
            <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
            <IdleSettings>
                <StopOnIdleEnd>true</StopOnIdleEnd>
                <RestartOnIdle>false</RestartOnIdle>
            </IdleSettings>
            <AllowStartOnDemand>true</AllowStartOnDemand>
            <Enabled>true</Enabled>
            <Hidden>false</Hidden>
            <RunOnlyIfIdle>false</RunOnlyIfIdle>
            <WakeToRun>false</WakeToRun>
            <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
            <Priority>7</Priority>
            <RestartOnFailure>
                <Interval>PT1M</Interval>
                <Count>3</Count>
            </RestartOnFailure>
        </Settings>
        <Triggers>
            <LogonTrigger>
                <Enabled>true</Enabled>
                <UserId>$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)</UserId>
            </LogonTrigger>
            $(foreach ($scheduledTaskTime in $scheduledTaskTimes) {
                "<CalendarTrigger>
                    <StartBoundary>$($scheduledTaskTime.ToString("s"))</StartBoundary>
                    <Enabled>true</Enabled>
                    <ScheduleByDay>
                        <DaysInterval>1</DaysInterval>
                    </ScheduleByDay>
                </CalendarTrigger>"
            })
        </Triggers>
        <Actions Context=`"Author`">
            <Exec>
                <Command>$scheduledTaskCommand</Command>
                <Arguments>$scheduledTaskArguments</Arguments>
                <WorkingDirectory>$($pwd.Path)</WorkingDirectory>
            </Exec>
        </Actions>
    </Task>
"
$newTemporaryFilePath = $env:TEMP + "\" + (New-TemporaryFile).Name
$scheduledTaskXmlRepresentation | Out-File $newTemporaryFilePath
schtasks /Delete /TN $scheduledTaskName /F 2>&1 | Out-Null
schtasks /Create /TN $scheduledTaskName /XML $newTemporaryFilePath
Remove-Item $newTemporaryFilePath
Start-ScheduledTask $scheduledTaskName
