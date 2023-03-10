[CmdletBinding()]
param (
    [System.Nullable[bool]] $EnableDarkMode,
    [System.Nullable[bool]] $EnableNightLight
)


$USER32 = Add-Type -MemberDefinition "
        [DllImport(`"user32.dll`", CharSet = CharSet.Unicode)] public static extern bool SystemParametersInfoW(uint uiAction, uint uiParam, string pvParam, uint fWinIni);
        [DllImport(`"user32.dll`", CharSet = CharSet.Unicode)] public static extern bool SendNotifyMessageW(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam);
        [DllImport(`"user32.dll`", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowExW(IntPtr hWndParent, IntPtr hWndChildAfter, IntPtr lpszClass, IntPtr lpszWindow);
        [DllImport(`"user32.dll`", CharSet = CharSet.Unicode)] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport(`"user32.dll`", CharSet = CharSet.Unicode)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
        [DllImport(`"user32.dll`", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
    " -Name "USER32" -PassThru
$USER32_SPI_SETDESKWALLPAPER = 0x14
$USER32_SPIF_UPDATEINIFILE = 0x1
$USER32_HWND_BROADCAST = [System.IntPtr]0xFFFF
$USER32_SW_SHOWMINIMIZED = 2
$USER32_WM_CLOSE = 0x10
$USER32_WM_SETTINGCHANGE = 0x1A
$APPS_FOLDER_PATH = "shell:AppsFolder"
$IMMERSIVE_CONTROL_PANEL_APP_NAME = "windows.immersivecontrolpanel"
$IMMERSIVE_CONTROL_PANEL_APP_NATIVE_PROCESS_NAME = "SystemSettings"
$IMMERSIVE_CONTROL_PANEL_APP_TITLES = ("Settings", "הגדרות")    # If your system is in another language, please translate the word "Settings" to that language and add it to the list.
$APPLICATION_FRAME_HOST_PROCESS_NAME = "ApplicationFrameHost"
$LIGHT_WALLPAPER_IMAGE_PATH = "C:\WINDOWS\web\wallpaper\Windows\img0.jpg"
$DARK_WALLPAPER_IMAGE_PATH = "C:\WINDOWS\web\wallpaper\Windows\img19.jpg"
$WINDOW_CAPTION_MAX_CHARACTER_COUNT = 1000
$SYSTEM_SETTINGS_APP_WINDOW_OPENING_WAITING_TIMEOUT_IN_MILLISECONDS = 1000

function Set-DarkModeState {
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
    Start-Sleep -Milliseconds 250
    $USER32::SendNotifyMessageW($USER32_HWND_BROADCAST, $USER32_WM_SETTINGCHANGE, [System.UIntPtr][uint32]0, "ImmersiveColorSet") | Out-Null
}

function Set-WallPaper {
    param (
        [Parameter(Mandatory=$true)] [string] $ImagePath
    )
    $USER32::SystemParametersInfoW($USER32_SPI_SETDESKWALLPAPER, 0, $ImagePath, $USER32_SPIF_UPDATEINIFILE) | Out-Null
}

function Set-NightLightState {
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
        $temp = ($temp -bor ([int64]($newData[10 + $i] -band 0x7F) -shl (7 * $i)))
    }
    $temp = ($temp -bor ([int64]($newData[14] -band 0xF) -shl 28))
    $temp++
    for ($i = 0; $i -lt 4; $i++) {
        $newData[10 + $i] = [byte]((($temp -shr (7 * $i)) -band 0x7F) -bor 0x80)
    }
    $newData[14] = [byte](($temp -shr 28) -band 0xF)
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate' -Name 'Data' -Value ([byte[]]$newData) -Type Binary
}

function Open-SystemSettingsApp {
    $apps = Get-StartApps
    $immersiveControlPanelAppPath = $null
    foreach ($app in $apps) {
        if ($app.AppID -match $IMMERSIVE_CONTROL_PANEL_APP_NAME) {
            $immersiveControlPanelAppPath = $APPS_FOLDER_PATH + "\" + $app.AppID
            break
        }
    }
    if (!(Get-Process $IMMERSIVE_CONTROL_PANEL_APP_NATIVE_PROCESS_NAME -ErrorAction SilentlyContinue)) {
        Start-Process $immersiveControlPanelAppPath
        return $true
    }
    return $false
}

function Get-SystemSettingsAppWindowHandle {
    $applicationFrameHostProcesses = [System.Diagnostics.Process]::GetProcessesByName($APPLICATION_FRAME_HOST_PROCESS_NAME)
    if ($applicationFrameHostProcesses.Length -gt 0) {
        $applicationFrameHostProcessIdOfCurrentUser = 0
        $sessionIdOfCurrentUser = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
        foreach ($applicationFrameHostProcess in $applicationFrameHostProcesses) {
            if ($applicationFrameHostProcess.SessionId -eq $sessionIdOfCurrentUser) {
                $applicationFrameHostProcessIdOfCurrentUser = $applicationFrameHostProcess.Id
                break
            }
        }
        if ($applicationFrameHostProcessIdOfCurrentUser -gt 0) {
            $currentWindowHandle = [System.IntPtr]::Zero
            do {
                $currentWindowHandle = $USER32::FindWindowExW([System.IntPtr]::Zero, $currentWindowHandle, [System.IntPtr]::Zero, [System.IntPtr]::Zero)
                $currentWindowProcessId = 0
                $USER32::GetWindowThreadProcessId($currentWindowHandle, [ref] $currentWindowProcessId) | Out-Null
                if ($currentWindowProcessId -eq $applicationFrameHostProcessIdOfCurrentUser) {
                    $currentWindowCaption = [System.Text.StringBuilder]::new($WINDOW_CAPTION_MAX_CHARACTER_COUNT)
                    $USER32::GetWindowTextW($currentWindowHandle, $currentWindowCaption, $WINDOW_CAPTION_MAX_CHARACTER_COUNT) | Out-Null
                    if ($IMMERSIVE_CONTROL_PANEL_APP_TITLES -contains $currentWindowCaption.ToString()) {
                        return $currentWindowHandle
                    }
                }
            } while ($currentWindowHandle -ne [System.IntPtr]::Zero)
        }
    }
    return [System.IntPtr]::Zero
}

function Wait-ForSystemSettingsAppWindowToBeOpenedAndGetWindowHandle {
    param (
        [System.Nullable[int]] $TimeoutInMilliseconds
    )
    $systemSettingsAppWindowHandle = [System.IntPtr]::Zero
    $startTime = Get-Date
    do {
        $systemSettingsAppWindowHandle = Get-SystemSettingsAppWindowHandle
        Start-Sleep -Milliseconds 100
    } while (($systemSettingsAppWindowHandle -eq [System.IntPtr]::Zero) -and `
                (($null -eq $TimeoutInMilliseconds) -or (((Get-Date) - $startTime).TotalMilliseconds -lt $TimeoutInMilliseconds)))
    return $systemSettingsAppWindowHandle
}

function Hide-Window {
    param (
        [System.IntPtr] $WindowHandle
    )
    if ($WindowHandle -ne [System.IntPtr]::Zero) {
        $USER32::ShowWindow($WindowHandle, $USER32_SW_SHOWMINIMIZED) | Out-Null
    }
}

function Close-Window {
    param (
        [System.IntPtr] $WindowHandle
    )
    if ($WindowHandle -ne [System.IntPtr]::Zero) {
        $USER32::SendNotifyMessageW($WindowHandle, $USER32_WM_CLOSE, [System.UIntPtr]::Zero, [System.IntPtr]::Zero) | Out-Null
    }
}


if ($null -ne $EnableDarkMode) {
    $systemSettingsAppWasNotAlreadyOpen = Open-SystemSettingsApp
    if ($systemSettingsAppWasNotAlreadyOpen) {
        $systemSettingsAppWindowHandle = Wait-ForSystemSettingsAppWindowToBeOpenedAndGetWindowHandle $SYSTEM_SETTINGS_APP_WINDOW_OPENING_WAITING_TIMEOUT_IN_MILLISECONDS
        Hide-Window $systemSettingsAppWindowHandle
        Set-DarkModeState $EnableDarkMode
        Close-Window $systemSettingsAppWindowHandle
    } else {
        Set-DarkModeState $EnableDarkMode
    }
    Set-WallPaper @($LIGHT_WALLPAPER_IMAGE_PATH, $DARK_WALLPAPER_IMAGE_PATH)[$EnableDarkMode]
}
if ($null -ne $EnableNightLight) {
    Set-NightLightState $EnableNightLight
}
