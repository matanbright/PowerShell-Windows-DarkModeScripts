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