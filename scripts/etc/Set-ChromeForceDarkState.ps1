[CmdletBinding()]
param (
    [System.Nullable[bool]] $EnableForceDark
)


$CHROME_PROCESS_NAME = "chrome"
$CHROME_LOCAL_STATE_FILE_PATH = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
$FORCE_DARK_ENABLE_FLAG_STRING = "enable-force-dark@1"


if ($null -ne $EnableForceDark) {
    Wait-Process $CHROME_PROCESS_NAME -ErrorAction SilentlyContinue
    $chromeLocalStateJson = Get-Content $CHROME_LOCAL_STATE_FILE_PATH -raw | ConvertFrom-Json
    $chromeLocalStateJson.browser | Add-Member -MemberType NoteProperty -Name "enabled_labs_experiments" -Value @() -ErrorAction SilentlyContinue
    $enabledLabsExperimentsArrayList = [System.Collections.ArrayList] $chromeLocalStateJson.browser.enabled_labs_experiments
    if ($EnableForceDark) {
        if ($enabledLabsExperimentsArrayList -notcontains $FORCE_DARK_ENABLE_FLAG_STRING) {
            $enabledLabsExperimentsArrayList.Add($FORCE_DARK_ENABLE_FLAG_STRING) | Out-Null
        }
    } else {
        if ($enabledLabsExperimentsArrayList -contains $FORCE_DARK_ENABLE_FLAG_STRING) {
            $enabledLabsExperimentsArrayList.Remove($FORCE_DARK_ENABLE_FLAG_STRING) | Out-Null
        }
    }
    $chromeLocalStateJson.browser.enabled_labs_experiments = $enabledLabsExperimentsArrayList.ToArray()
    $chromeLocalStateJson | ConvertTo-Json -depth 32 | Set-Content $CHROME_LOCAL_STATE_FILE_PATH
}
