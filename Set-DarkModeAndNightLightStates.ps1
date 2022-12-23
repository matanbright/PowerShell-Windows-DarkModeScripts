[CmdletBinding()]
param (
    [System.Nullable[System.DateTime]] $darkModeStartTime,
    [System.Nullable[System.DateTime]] $darkModeEndTime,
    [System.Nullable[System.DateTime]] $nightLightStartTime,
    [System.Nullable[System.DateTime]] $nightLightEndTime
)


function Get-IfShouldEnableDarkMode {
    param (
        [System.DateTime] $timeToCheckAgainst
    )
    if (($darkModeStartTime -ne $null) -and ($darkModeEndTime -ne $null)) {
        $newDarkModeStartTime = Get-Date -Hour $darkModeStartTime.Hour -Minute $darkModeStartTime.Minute -Second $darkModeStartTime.Second
        $newDarkModeEndTime = Get-Date -Hour $darkModeEndTime.Hour -Minute $darkModeEndTime.Minute -Second $darkModeEndTime.Second
        if ($darkModeStartTime -le $darkModeEndTime) {
            return (($timeToCheckAgainst -ge $newDarkModeStartTime) -and ($timeToCheckAgainst -lt $newDarkModeEndTime))
        } else {
            return (($timeToCheckAgainst -ge $newDarkModeStartTime) -or ($timeToCheckAgainst -lt $newDarkModeEndTime))
        }
    }
    return $null
}

function Get-IfShouldEnableNightLight {
    param (
        [System.DateTime] $timeToCheckAgainst
    )
    if (($nightLightStartTime -ne $null) -and ($nightLightEndTime -ne $null)) {
        $newNightLightStartTime = Get-Date -Hour $nightLightStartTime.Hour -Minute $nightLightStartTime.Minute -Second $nightLightStartTime.Second
        $newNightLightEndTime = Get-Date -Hour $nightLightEndTime.Hour -Minute $nightLightEndTime.Minute -Second $nightLightEndTime.Second
        if ($nightLightStartTime -le $nightLightEndTime) {
            return (($timeToCheckAgainst -ge $newNightLightStartTime) -and ($timeToCheckAgainst -lt $newNightLightEndTime))
        } else {
            return (($timeToCheckAgainst -ge $newNightLightStartTime) -or ($timeToCheckAgainst -lt $newNightLightEndTime))
        }
    }
    return $null
}

function Start-JobHere() {
    param (
        [System.Management.Automation.ScriptBlock] $scriptBlock,
        [System.Object[]] $arguments
    )
    return Start-Job -Init ([System.Management.Automation.ScriptBlock]::Create("Set-Location `"$pwd`"")) -ScriptBlock $scriptBlock -ArgumentList $arguments
}


$currentTime = Get-Date
$shouldEnableDarkMode = Get-IfShouldEnableDarkMode $currentTime
$shouldEnableNightLight = Get-IfShouldEnableNightLight $currentTime
# Add scripts below:
$jobList = @()
$jobList += Start-JobHere { scripts\Set-WindowsDarkModeAndNightLightStates.ps1 $args[0] $args[1] } ($shouldEnableDarkMode, $shouldEnableNightLight)
$jobList += Start-JobHere { scripts\etc\Set-ChromeForceDarkState.ps1 $args[0] } $shouldEnableDarkMode
$jobList += Start-JobHere { scripts\etc\Set-NotepadPlusPlusDarkModeState.ps1 $args[0] } $shouldEnableDarkMode
Wait-Job $jobList
