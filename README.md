# PowerShell-Windows11-SetDarkModeAndNightLightStates

This PowerShell script sets the dark-mode's and night-light's states of the Windows OS according to the given times. It can be used in a scheduled task.\
Please note: it also changes the desktop's wallpaper to the default Windows light or dark wallpaper.

It works by manipulating some strange registry values and calling a system call for changing the desktop's wallpaper.

_Tested on Windows 11 (version 21H2, build 22000.708)._
