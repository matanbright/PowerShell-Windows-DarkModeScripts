[CmdletBinding()]
param (
    [System.Nullable[bool]] $EnableDarkMode
)


$NOTEPAD_PLUS_PLUS_PROCESS_NAME = "notepad++"
$NOTEPAD_PLUS_PLUS_CONFIG_FILE_PATH = "$env:APPDATA\Notepad++\config.xml"
$GUI_CONFIG_DARK_MODE_XML_NODE_XPATH = "//GUIConfig[@name = `"DarkMode`"]"
$GUI_CONFIG_STYLER_THEME_XML_NODE_XPATH = "//GUIConfig[@name = `"stylerTheme`"]"
$STYLER_THEME_PATH_WHEN_DARK_MODE_IS_DISABLED = "C:\Users\Matan\AppData\Roaming\Notepad++\stylers.xml"
$STYLER_THEME_PATH_WHEN_DARK_MODE_IS_ENABLED = "C:\Program Files\Notepad++\themes\DarkModeDefault.xml"


if ($EnableDarkMode -ne $null) {
    Wait-Process $NOTEPAD_PLUS_PLUS_PROCESS_NAME -ErrorAction SilentlyContinue
    $notepadPlusPlusConfigXml = [System.Xml.XmlDocument]::new()
    $notepadPlusPlusConfigXml.Load($NOTEPAD_PLUS_PLUS_CONFIG_FILE_PATH)
    $guiConfigDarkModeXmlNode = $notepadPlusPlusConfigXml.SelectNodes($GUI_CONFIG_DARK_MODE_XML_NODE_XPATH)
    $guiConfigStylerThemeXmlNode = $notepadPlusPlusConfigXml.SelectNodes($GUI_CONFIG_STYLER_THEME_XML_NODE_XPATH)
    if ($EnableDarkMode) {
        $guiConfigDarkModeXmlNode.SetAttribute("enable", "yes")
        $guiConfigStylerThemeXmlNode.SetAttribute("path", $STYLER_THEME_PATH_WHEN_DARK_MODE_IS_ENABLED)
    } else {
        $guiConfigDarkModeXmlNode.SetAttribute("enable", "no")
        $guiConfigStylerThemeXmlNode.SetAttribute("path", $STYLER_THEME_PATH_WHEN_DARK_MODE_IS_DISABLED)
    }
    $notepadPlusPlusConfigXml.Save($NOTEPAD_PLUS_PLUS_CONFIG_FILE_PATH)
}
