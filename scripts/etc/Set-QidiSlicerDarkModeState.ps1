[CmdletBinding()]
param (
    [System.Nullable[bool]] $EnableDarkMode
)


$QIDI_SLICER_PROCESS_NAME = "qidi-slicer"
$QIDI_SLICER_CONFIG_FILE_PATH = "$env:APPDATA\QIDISlicer\QIDISlicer.ini"
$DARK_MODE_STRING = "dark_color_mode"


if ($null -ne $EnableDarkMode) {
    Wait-Process $QIDI_SLICER_PROCESS_NAME -ErrorAction SilentlyContinue
    if (Test-Path $QIDI_SLICER_CONFIG_FILE_PATH) {
        $qidiSlicerConfigFileLines = Get-Content $QIDI_SLICER_CONFIG_FILE_PATH
        $newQidiSlicerConfigFileLines = [System.Collections.Generic.List[String]]::new()
        foreach ($qidiSlicerConfigFileLine in $qidiSlicerConfigFileLines) {
            if ($qidiSlicerConfigFileLine -clike ($DARK_MODE_STRING + "*")) {
                $darkModeEnableValue = "0"
                if ($EnableDarkMode) {
                    $darkModeEnableValue = "1"
                }
                $newQidiSlicerConfigFileLines.Add($DARK_MODE_STRING + " = " + $darkModeEnableValue)
            } else {
                $newQidiSlicerConfigFileLines.Add($qidiSlicerConfigFileLine)
            }
        }
        $newQidiSlicerConfigFileLines | Set-Content $QIDI_SLICER_CONFIG_FILE_PATH
    }
}
