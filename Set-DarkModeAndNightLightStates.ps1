[CmdletBinding()]
param (
    [System.Nullable[System.DateTime]] $DarkModeStartTime,
    [System.Nullable[System.DateTime]] $DarkModeEndTime,
    [System.Nullable[System.DateTime]] $NightLightStartTime,
    [System.Nullable[System.DateTime]] $NightLightEndTime
)


function Get-IfShouldEnableDarkMode {
    param (
        [System.DateTime] $TimeToCheckAgainst
    )
    if (($DarkModeStartTime -ne $null) -and ($DarkModeEndTime -ne $null)) {
        $newDarkModeStartTime = Get-Date -Hour $DarkModeStartTime.Hour -Minute $DarkModeStartTime.Minute -Second $DarkModeStartTime.Second
        $newDarkModeEndTime = Get-Date -Hour $DarkModeEndTime.Hour -Minute $DarkModeEndTime.Minute -Second $DarkModeEndTime.Second
        if ($DarkModeStartTime -le $DarkModeEndTime) {
            return (($TimeToCheckAgainst -ge $newDarkModeStartTime) -and ($TimeToCheckAgainst -lt $newDarkModeEndTime))
        } else {
            return (($TimeToCheckAgainst -ge $newDarkModeStartTime) -or ($TimeToCheckAgainst -lt $newDarkModeEndTime))
        }
    }
    return $null
}

function Get-IfShouldEnableNightLight {
    param (
        [System.DateTime] $TimeToCheckAgainst
    )
    if (($NightLightStartTime -ne $null) -and ($NightLightEndTime -ne $null)) {
        $newNightLightStartTime = Get-Date -Hour $NightLightStartTime.Hour -Minute $NightLightStartTime.Minute -Second $NightLightStartTime.Second
        $newNightLightEndTime = Get-Date -Hour $NightLightEndTime.Hour -Minute $NightLightEndTime.Minute -Second $NightLightEndTime.Second
        if ($NightLightStartTime -le $NightLightEndTime) {
            return (($TimeToCheckAgainst -ge $newNightLightStartTime) -and ($TimeToCheckAgainst -lt $newNightLightEndTime))
        } else {
            return (($TimeToCheckAgainst -ge $newNightLightStartTime) -or ($TimeToCheckAgainst -lt $newNightLightEndTime))
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
#$jobList += Start-JobHere { scripts\etc\Set-NotepadPlusPlusDarkModeState.ps1 $args[0] } $shouldEnableDarkMode
#####################################################################################
Wait-Job $jobList
