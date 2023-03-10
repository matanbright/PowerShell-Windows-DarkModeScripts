[CmdletBinding()]
param (
    [System.Nullable[bool]] $EnableDarkMode
)


$CURA_PROCESS_NAME = "UltiMaker-Cura"
$CURA_CONFIG_DIRECTORY_PATH = "$env:APPDATA\cura"
$CURA_CONFIG_FILE_NAME = "cura.cfg"
$CURA_DARK_MODE_CONFIG_SECTION = "[general]"
$CURA_DARK_MODE_ENABLE_CLAUSE = "theme = cura-dark"


if ($null -ne $EnableDarkMode) {
    Wait-Process $CURA_PROCESS_NAME -ErrorAction SilentlyContinue
    if (Test-Path $CURA_CONFIG_DIRECTORY_PATH) {
        $curaConfigSubDirectories = Get-ChildItem -Directory $CURA_CONFIG_DIRECTORY_PATH | Foreach-Object Name
        foreach ($curaConfigSubDirectory in $curaConfigSubDirectories) {
            $curaConfigFilePath = $CURA_CONFIG_DIRECTORY_PATH + "\" + $curaConfigSubDirectory + "\" + $CURA_CONFIG_FILE_NAME
            if (Test-Path $curaConfigFilePath) {
                $curaConfigFileLines = Get-Content $curaConfigFilePath
                $newCuraConfigFileLines = $null
                if ($EnableDarkMode) {
                    if ($curaConfigFileLines -notcontains $CURA_DARK_MODE_ENABLE_CLAUSE) {
                        $newCuraConfigFileLines = [String[]]::new($curaConfigFileLines.Length + 1)
                        $currentIndex = 0
                        foreach ($curaConfigFileLine in $curaConfigFileLines) {
                            $newCuraConfigFileLines[$currentIndex] = $curaConfigFileLine
                            $currentIndex++
                            if ($curaConfigFileLine -eq $CURA_DARK_MODE_CONFIG_SECTION) {
                                $newCuraConfigFileLines[$currentIndex] = $CURA_DARK_MODE_ENABLE_CLAUSE
                                $currentIndex++
                            }
                        }
                    }
                } else {
                    if ($curaConfigFileLines -contains $CURA_DARK_MODE_ENABLE_CLAUSE) {
                        $newCuraConfigFileLines = [String[]]::new($curaConfigFileLines.Length - 1)
                        $currentIndex = 0
                        foreach ($curaConfigFileLine in $curaConfigFileLines) {
                            if ($curaConfigFileLine -ne $CURA_DARK_MODE_ENABLE_CLAUSE) {
                                $newCuraConfigFileLines[$currentIndex] = $curaConfigFileLine
                                $currentIndex++
                            }
                        }
                    }
                }
                if ($null -ne $newCuraConfigFileLines) {
                    $newCuraConfigFileLines | Set-Content $curaConfigFilePath
                }
            }
        }
    }
}
