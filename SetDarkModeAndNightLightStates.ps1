[CmdletBinding()]
param (
    [DateTime] $DarkModeStartTime,
    [DateTime] $DarkModeEndTime,
    [DateTime] $NightLightStartTime,
    [DateTime] $NightLightEndTime
)


$User32 = Add-Type -MemberDefinition "
        [DllImport(`"user32.dll`", CharSet = CharSet.Unicode)]
        public static extern int SystemParametersInfo(uint uiAction,
                                                      uint uiParam,
                                                      String pvParam,
                                                      uint fWinIni);
    " -Name "User32" -PassThru
$USER32_SPI_SETDESKWALLPAPER = 0x14
$USER32_SPIF_UPDATEINIFILE = 0x1
$LIGHT_WALLPAPER_IMAGE_PATH = "C:\WINDOWS\web\wallpaper\Windows\img0.jpg"
$DARK_WALLPAPER_IMAGE_PATH = "C:\WINDOWS\web\wallpaper\Windows\img19.jpg"

function Set-DarkModeEnabled {
    param (
        [Parameter(Mandatory=$true)] [bool] $Enabled
    )
    if ($Enabled) {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0
    } else {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1
    }
}

function Set-WallPaper {
    param (
        [Parameter(Mandatory=$true)] [string] $ImagePath
    )
    $User32::SystemParametersInfo($USER32_SPI_SETDESKWALLPAPER, 0, $ImagePath, $USER32_SPIF_UPDATEINIFILE)
}

function Set-NightLightEnabled {
    param (
        [Parameter(Mandatory=$true)] [bool] $Enabled
    )
    $currentData = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate' -Name 'Data').Data
    $newData = @()
    for ($i = 0; $i -lt 23; $i++) {
        $newData += $currentData[$i]
    }
    if (($currentData.Length -eq 41) -and ($currentData[18] -eq 0x13) -and $Enabled) {
        $newData[18] = 0x15
        $newData += (0x10, 0x00)
        for ($i = 23; $i -lt $currentData.Length; $i++) {
            $newData += $currentData[$i]
        }
    } elseif (($currentData.Length -eq 43) -and ($currentData[18] -eq 0x15) -and (-not $Enabled)) {
        $newData[18] = 0x13
        for ($i = 25; $i -lt $currentData.Length; $i++) {
            $newData += $currentData[$i]
        }
    } else {
        return
    }
    $temp = [Int64]0x0
    for ($i = 0; $i -lt 4; $i++) {
        $temp = ($temp -bor ([Int64]($newData[10 + $i] -band 0x7F) -shl (7 * $i)))
    }
    $temp = ($temp -bor ([Int64]($newData[14] -band 0xF) -shl 28))
    $temp++
    for ($i = 0; $i -lt 4; $i++) {
        $newData[10 + $i] = [byte]((($temp -shr (7 * $i)) -band 0x7F) -bor 0x80)
    }
    $newData[14] = [byte](($temp -shr 28) -band 0xF)
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate' -Name 'Data' -Value ([byte[]]$newData) -Type Binary
}

function Set-DarkModeChrome {
    Write-Output "Changing google chrome to dark mode:"
    $chrome_process = Get-Process chrome -ErrorAction SilentlyContinue
    if ($chrome_process) {
        $confirmation = Read-Host "Chrome need to be closed to procced. Should we close it? [Y\n]"
        if ($confirmation -eq 'y' -Or $confirmation -eq 'Y' -Or !$confirmation) {
            Write-Output "Closing chrome application..."
            $chrome_process.CloseMainWindow()
            Sleep 3
            if (!$chrome_process.HasExited) {
            $chrome_process | Stop-Process -Force
            }
        }
    }
}

$currentTime = (Get-Date -Day 1 -Month 1 -Year 1970)
if (($DarkModeStartTime -ne $null) -and ($DarkModeEndTime -ne $null)) {
    $newDarkModeStartTime = (Get-Date -Day 1 -Month 1 -Year 1970 -Hour $DarkModeStartTime.Hour -Minute $DarkModeStartTime.Minute -Second $DarkModeStartTime.Second)
    $newDarkModeEndTime = (Get-Date -Day 1 -Month 1 -Year 1970 -Hour $DarkModeEndTime.Hour -Minute $DarkModeEndTime.Minute -Second $DarkModeEndTime.Second)
    $shouldEnableDarkMode = $false
    if ($DarkModeStartTime -le $DarkModeEndTime) {
        $shouldEnableDarkMode = (($currentTime -ge $newDarkModeStartTime) -and ($currentTime -lt $newDarkModeEndTime))
    } else {
        $shouldEnableDarkMode = (($currentTime -ge $newDarkModeStartTime) -or ($currentTime -lt $newDarkModeEndTime))
    }
    Set-DarkModeEnabled $shouldEnableDarkMode
    Set-WallPaper @($LIGHT_WALLPAPER_IMAGE_PATH, $DARK_WALLPAPER_IMAGE_PATH)[$shouldEnableDarkMode]
}
if (($NightLightStartTime -ne $null) -and ($NightLightEndTime -ne $null)) {
    $newNightLightStartTime = (Get-Date -Day 1 -Month 1 -Year 1970 -Hour $NightLightStartTime.Hour -Minute $NightLightStartTime.Minute -Second $NightLightStartTime.Second)
    $newNightLightEndTime = (Get-Date -Day 1 -Month 1 -Year 1970 -Hour $NightLightEndTime.Hour -Minute $NightLightEndTime.Minute -Second $NightLightEndTime.Second)
    $shouldEnableNightLight = $false
    if ($NightLightStartTime -le $NightLightEndTime) {
        $shouldEnableNightLight = (($currentTime -ge $newNightLightStartTime) -and ($currentTime -lt $newNightLightEndTime))
    } else {
        $shouldEnableNightLight = (($currentTime -ge $newNightLightStartTime) -or ($currentTime -lt $newNightLightEndTime))
    }
    Set-NightLightEnabled $shouldEnableNightLight
}
