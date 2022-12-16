# PowerShell-Windows11-SetDarkModeAndNightLightStates
## Explanation
This PowerShell script sets the dark-mode's and night-light's states of the Windows OS according to the given times. It can be used in a scheduled task.\
Please note: it also changes the desktop's wallpaper to the default Windows light or dark wallpaper.

It works by manipulating some strange registry values and calling a system call for changing the desktop's wallpaper.

Google Chrome added an option to auto dark mode for web contents, that is render all web contents using a dark theme
(Note: This is an experimental feature of Google Chrome)
You are more than welcome to try the dark mode automation script for Google Chrome.
## Compatibility:
- _Windows 11 (version 21H2, build 22000.708)_
- _Windows 11 (version 22H2, build 22621.963)_
## Usage:
Open powershell and execute:

Time format : `HH:MM`
```
./SetDarkModeAndNightLightStates.ps1 [DarkModeStartTime] [DarkModeEndTime] [NightLightStartTime] [NightLightEndTime]
```

- To run the dark mode for Google chrome execute:
- [FLAG] = 1 - to enable dark mode, 2 - to disable dark mode
```
./SetChromeDarkModeState.ps1 [FLAG]
```