[CmdletBinding()]
param (
    [System.Nullable[bool]] $EnableDarkMode
)


$INKSCAPE_PROCESS_NAME = "inkscape"
$INKSCAPE_CONFIG_FILE_PATH = "$env:APPDATA\inkscape\preferences.xml"
$GROUP_THEME_XML_NODE_XPATH = "//group[@id = `"theme`"]"


if ($null -ne $EnableDarkMode) {
    Wait-Process $INKSCAPE_PROCESS_NAME -ErrorAction SilentlyContinue
    if (Test-Path $INKSCAPE_CONFIG_FILE_PATH) {
        $inkscapeConfigXml = [System.Xml.XmlDocument]::new()
        $inkscapeConfigXml.Load($INKSCAPE_CONFIG_FILE_PATH)
        $groupThemeXmlNode = $inkscapeConfigXml.SelectNodes($GROUP_THEME_XML_NODE_XPATH)
        if ($EnableDarkMode) {
            $groupThemeXmlNode.SetAttribute("preferDarkTheme", "1")
            $groupThemeXmlNode.SetAttribute("darkTheme", "1")
        } else {
            $groupThemeXmlNode.SetAttribute("preferDarkTheme", "0")
            $groupThemeXmlNode.SetAttribute("darkTheme", "0")
        }
        $inkscapeConfigXml.Save($INKSCAPE_CONFIG_FILE_PATH)
    }
}
