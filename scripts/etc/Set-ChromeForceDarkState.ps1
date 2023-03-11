[CmdletBinding()]
param (
    [System.Nullable[bool]] $EnableForceDark
)


$CHROME_PROCESS_NAME = "chrome"
$CHROME_CONFIG_FILE_PATH = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
$BROWSER_JSON_KEY = "browser"
$ENABLED_LABS_EXPERIMENTS_JSON_KEY = "enabled_labs_experiments"
$FORCE_DARK_ENABLE_CLAUSE = "enable-force-dark@1"


if ($null -ne $EnableForceDark) {
    Wait-Process $CHROME_PROCESS_NAME -ErrorAction SilentlyContinue
    if (Test-Path $CHROME_CONFIG_FILE_PATH) {
        $chromeLocalStateJson = Get-Content $CHROME_CONFIG_FILE_PATH -raw | ConvertFrom-Json
        $chromeLocalStateJson.$BROWSER_JSON_KEY | Add-Member -MemberType NoteProperty -Name $ENABLED_LABS_EXPERIMENTS_JSON_KEY -Value @() -ErrorAction SilentlyContinue
        $enabledLabsExperimentsArrayList = [System.Collections.ArrayList] $chromeLocalStateJson.$BROWSER_JSON_KEY.$ENABLED_LABS_EXPERIMENTS_JSON_KEY
        if ($EnableForceDark) {
            if ($enabledLabsExperimentsArrayList -notcontains $FORCE_DARK_ENABLE_CLAUSE) {
                $enabledLabsExperimentsArrayList.Add($FORCE_DARK_ENABLE_CLAUSE) | Out-Null
            }
        } else {
            if ($enabledLabsExperimentsArrayList -contains $FORCE_DARK_ENABLE_CLAUSE) {
                $enabledLabsExperimentsArrayList.Remove($FORCE_DARK_ENABLE_CLAUSE) | Out-Null
            }
        }
        $chromeLocalStateJson.$BROWSER_JSON_KEY.$ENABLED_LABS_EXPERIMENTS_JSON_KEY = $enabledLabsExperimentsArrayList.ToArray()
        $chromeLocalStateJson | ConvertTo-Json -depth 32 | Set-Content $CHROME_CONFIG_FILE_PATH
    }
}
