[CmdletBinding()]
param (
    [System.Nullable[System.DateTime]] $DarkModeStartTime,
    [System.Nullable[System.DateTime]] $DarkModeEndTime,
    [System.Nullable[System.DateTime]] $NightLightStartTime,
    [System.Nullable[System.DateTime]] $NightLightEndTime
)


$ACCEPTABLE_TIME_DEVIATION_IN_MILLISECONDS = 1000


function Get-IfShouldEnableDarkMode {
    param (
        [System.DateTime] $TimeToCheckAgainst
    )
    $newTimeToCheckAgainst = (Get-Date -Day 1 -Month 1 -Year 1970 -Hour $TimeToCheckAgainst.Hour -Minute $TimeToCheckAgainst.Minute -Second $TimeToCheckAgainst.Second).AddMilliseconds($ACCEPTABLE_TIME_DEVIATION_IN_MILLISECONDS)
    if (($null -ne $DarkModeStartTime) -and ($null -ne $DarkModeEndTime)) {
        $newDarkModeStartTime = Get-Date -Day 1 -Month 1 -Year 1970 -Hour $DarkModeStartTime.Hour -Minute $DarkModeStartTime.Minute -Second $DarkModeStartTime.Second
        $newDarkModeEndTime = Get-Date -Day 1 -Month 1 -Year 1970 -Hour $DarkModeEndTime.Hour -Minute $DarkModeEndTime.Minute -Second $DarkModeEndTime.Second
        if ($DarkModeStartTime -le $DarkModeEndTime) {
            return (($newTimeToCheckAgainst -ge $newDarkModeStartTime) -and ($newTimeToCheckAgainst -lt $newDarkModeEndTime))
        } else {
            return (($newTimeToCheckAgainst -ge $newDarkModeStartTime) -or ($newTimeToCheckAgainst -lt $newDarkModeEndTime))
        }
    }
    return $null
}

function Get-IfShouldEnableNightLight {
    param (
        [System.DateTime] $TimeToCheckAgainst
    )
    $newTimeToCheckAgainst = (Get-Date -Day 1 -Month 1 -Year 1970 -Hour $TimeToCheckAgainst.Hour -Minute $TimeToCheckAgainst.Minute -Second $TimeToCheckAgainst.Second).AddMilliseconds($ACCEPTABLE_TIME_DEVIATION_IN_MILLISECONDS)
    if (($null -ne $NightLightStartTime) -and ($null -ne $NightLightEndTime)) {
        $newNightLightStartTime = Get-Date -Day 1 -Month 1 -Year 1970 -Hour $NightLightStartTime.Hour -Minute $NightLightStartTime.Minute -Second $NightLightStartTime.Second
        $newNightLightEndTime = Get-Date -Day 1 -Month 1 -Year 1970 -Hour $NightLightEndTime.Hour -Minute $NightLightEndTime.Minute -Second $NightLightEndTime.Second
        if ($NightLightStartTime -le $NightLightEndTime) {
            return (($newTimeToCheckAgainst -ge $newNightLightStartTime) -and ($newTimeToCheckAgainst -lt $newNightLightEndTime))
        } else {
            return (($newTimeToCheckAgainst -ge $newNightLightStartTime) -or ($newTimeToCheckAgainst -lt $newNightLightEndTime))
        }
    }
    return $null
}

function Start-JobHere() {
    param (
        [System.Management.Automation.ScriptBlock] $ScriptBlock,
        [System.Object[]] $Arguments
    )
    return Start-Job -Init ([System.Management.Automation.ScriptBlock]::Create("Set-Location `"$pwd`"")) -ScriptBlock $ScriptBlock -ArgumentList $Arguments
}


$currentTime = Get-Date
$shouldEnableDarkMode = Get-IfShouldEnableDarkMode $currentTime
$shouldEnableNightLight = Get-IfShouldEnableNightLight $currentTime
$jobList = @()
###### Below you can comment/uncomment/add lines to enable/disable/add scripts ######
$jobList += Start-JobHere { scripts\Set-WindowsDarkModeAndNightLightStates.ps1 $args[0] $args[1] } ($shouldEnableDarkMode, $shouldEnableNightLight)
#$jobList += Start-JobHere { scripts\etc\Set-ChromeForceDarkState.ps1 $args[0] } $shouldEnableDarkMode
#$jobList += Start-JobHere { scripts\etc\Set-InkscapeDarkModeState.ps1 $args[0] } $shouldEnableDarkMode
#$jobList += Start-JobHere { scripts\etc\Set-CuraDarkModeState.ps1 $args[0] } $shouldEnableDarkMode
#####################################################################################
Wait-Job $jobList
