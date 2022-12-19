[CmdletBinding()]
param (
    [DateTime] $darkModeStartTime,
    [DateTime] $darkModeEndTime,
    [DateTime] $nightLightStartTime,
    [DateTime] $nightLightEndTime
)


$USER32 = Add-Type -MemberDefinition "
        [DllImport(`"user32.dll`", CharSet = CharSet.Unicode)]
        public static extern bool SystemParametersInfoW(uint uiAction,
                                                        uint uiParam,
                                                        String pvParam,
                                                        uint fWinIni);
        [DllImport(`"user32.dll`", CharSet = CharSet.Unicode)]
        public static extern bool SendNotifyMessageW(IntPtr hWnd,
                                                     uint Msg,
                                                     UIntPtr wParam,
                                                     String lParam);
    " -Name "USER32" -PassThru
$USER32_SPI_SETDESKWALLPAPER = 0x14
$USER32_SPIF_UPDATEINIFILE = 0x1
$USER32_HWND_BROADCAST = [IntPtr]0xFFFF
$USER32_WM_SETTINGCHANGE = 0x1A
$LIGHT_WALLPAPER_IMAGE_PATH = "C:\WINDOWS\web\wallpaper\Windows\img0.jpg"
$DARK_WALLPAPER_IMAGE_PATH = "C:\WINDOWS\web\wallpaper\Windows\img19.jpg"

function Set-DarkModeEnabled {
    param (
        [Parameter(Mandatory=$true)] [bool] $enabled
    )
    if ($enabled) {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0
    } else {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1
    }
    Start-Sleep -Milliseconds 250
    $USER32::SendNotifyMessageW($USER32_HWND_BROADCAST, $USER32_WM_SETTINGCHANGE, [UIntPtr][uint32]0, "ImmersiveColorSet")
}

function Set-WallPaper {
    param (
        [Parameter(Mandatory=$true)] [string] $imagePath
    )
    $USER32::SystemParametersInfoW($USER32_SPI_SETDESKWALLPAPER, 0, $imagePath, $USER32_SPIF_UPDATEINIFILE)
}

function Set-NightLightEnabled {
    param (
        [Parameter(Mandatory=$true)] [bool] $enabled
    )
    $currentData = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate' -Name 'Data').Data
    $newData = @()
    for ($i = 0; $i -lt 23; $i++) {
        $newData += $currentData[$i]
    }
    if (($currentData.Length -eq 41) -and ($currentData[18] -eq 0x13) -and $enabled) {
        $newData[18] = 0x15
        $newData += (0x10, 0x00)
        for ($i = 23; $i -lt $currentData.Length; $i++) {
            $newData += $currentData[$i]
        }
    } elseif (($currentData.Length -eq 43) -and ($currentData[18] -eq 0x15) -and (-not $enabled)) {
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


$currentTime = (Get-Date -Day 1 -Month 1 -Year 1970)
if (($darkModeStartTime -ne $null) -and ($darkModeEndTime -ne $null)) {
    $newDarkModeStartTime = (Get-Date -Day 1 -Month 1 -Year 1970 -Hour $darkModeStartTime.Hour -Minute $darkModeStartTime.Minute -Second $darkModeStartTime.Second)
    $newDarkModeEndTime = (Get-Date -Day 1 -Month 1 -Year 1970 -Hour $darkModeEndTime.Hour -Minute $darkModeEndTime.Minute -Second $darkModeEndTime.Second)
    $shouldEnableDarkMode = $false
    if ($darkModeStartTime -le $darkModeEndTime) {
        $shouldEnableDarkMode = (($currentTime -ge $newDarkModeStartTime) -and ($currentTime -lt $newDarkModeEndTime))
    } else {
        $shouldEnableDarkMode = (($currentTime -ge $newDarkModeStartTime) -or ($currentTime -lt $newDarkModeEndTime))
    }
    Set-DarkModeEnabled $shouldEnableDarkMode
    Set-WallPaper @($LIGHT_WALLPAPER_IMAGE_PATH, $DARK_WALLPAPER_IMAGE_PATH)[$shouldEnableDarkMode]
}
if (($nightLightStartTime -ne $null) -and ($nightLightEndTime -ne $null)) {
    $newNightLightStartTime = (Get-Date -Day 1 -Month 1 -Year 1970 -Hour $nightLightStartTime.Hour -Minute $nightLightStartTime.Minute -Second $nightLightStartTime.Second)
    $newNightLightEndTime = (Get-Date -Day 1 -Month 1 -Year 1970 -Hour $nightLightEndTime.Hour -Minute $nightLightEndTime.Minute -Second $nightLightEndTime.Second)
    $shouldEnableNightLight = $false
    if ($nightLightStartTime -le $nightLightEndTime) {
        $shouldEnableNightLight = (($currentTime -ge $newNightLightStartTime) -and ($currentTime -lt $newNightLightEndTime))
    } else {
        $shouldEnableNightLight = (($currentTime -ge $newNightLightStartTime) -or ($currentTime -lt $newNightLightEndTime))
    }
    Set-NightLightEnabled $shouldEnableNightLight
}
