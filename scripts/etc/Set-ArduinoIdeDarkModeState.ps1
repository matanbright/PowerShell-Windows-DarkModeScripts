[CmdletBinding()]
param (
    [System.Nullable[bool]] $EnableDarkMode
)


$ARDUINO_IDE_PROCESS_NAME = "Arduino IDE"
$ARDUINO_IDE_CONFIG_FILE_PATH = "$env:USERPROFILE\.arduinoIDE\settings.json"
$WORKBENCH_COLOR_THEME_JSON_KEY = "workbench.colorTheme"
$LIGHT_ARDUINO_THEME_NAME = "arduino-theme"
$DARK_ARDUINO_THEME_NAME = "arduino-theme-dark"


if ($null -ne $EnableDarkMode) {
    Wait-Process $ARDUINO_IDE_PROCESS_NAME -ErrorAction SilentlyContinue
    if (Test-Path $ARDUINO_IDE_CONFIG_FILE_PATH) {
        $arduinoIdeConfigJson = Get-Content $ARDUINO_IDE_CONFIG_FILE_PATH -raw | ConvertFrom-Json
        $arduinoIdeConfigJson | Add-Member -MemberType NoteProperty -Name $WORKBENCH_COLOR_THEME_JSON_KEY -Value "" -ErrorAction SilentlyContinue
        if ($EnableDarkMode) {
            $arduinoIdeConfigJson.$WORKBENCH_COLOR_THEME_JSON_KEY = $DARK_ARDUINO_THEME_NAME
        } else {
            $arduinoIdeConfigJson.$WORKBENCH_COLOR_THEME_JSON_KEY = $LIGHT_ARDUINO_THEME_NAME
        }
        $arduinoIdeConfigJson | ConvertTo-Json -depth 32 | Set-Content $ARDUINO_IDE_CONFIG_FILE_PATH
    }
}
