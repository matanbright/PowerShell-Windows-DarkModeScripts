[CmdletBinding()]
param (
    [bool] $EnableDarkMode
)


$CHROME_LOCAL_STATE_FILE_PATH = "C:\Users\$env:UserName\AppData\Local\Google\Chrome\User Data\Local State"
$ENABLE_FORCE_DARK_COMMAND = "enable-force-dark@1"

function Close-Chrome {
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

function Set-ChromeDarkMode {
    $chromeLocalStateJson = Get-Content $CHROME_LOCAL_STATE_FILE_PATH -raw | ConvertFrom-Json
    $enabledLabsExperimentsArrayList = [System.Collections.ArrayList] $chromeLocalStateJson.browser.enabled_labs_experiments
    if ($EnableDarkMode) {
        if ($enabledLabsExperimentsArrayList -notcontains $ENABLE_FORCE_DARK_COMMAND) {
            $enabledLabsExperimentsArrayList.Add($ENABLE_FORCE_DARK_COMMAND)
        }
    } else {
        if ($enabledLabsExperimentsArrayList -contains $ENABLE_FORCE_DARK_COMMAND) {
            $enabledLabsExperimentsArrayList.Remove($ENABLE_FORCE_DARK_COMMAND)
        }
    }
    $chromeLocalStateJson.browser.enabled_labs_experiments = $enabledLabsExperimentsArrayList.ToArray()
    $chromeLocalStateJson | ConvertTo-Json -depth 32 | Set-Content $CHROME_LOCAL_STATE_FILE_PATH
}

Write-Output "Changing google chrome to dark mode:"
Close-Chrome
Set-ChromeDarkMode