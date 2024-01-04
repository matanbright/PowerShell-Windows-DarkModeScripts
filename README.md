# PowerShell-Windows-DarkModeScripts

This repository contains PowerShell scripts for changing the dark-mode's and night-light's states of the Windows OS (and also of some applications).
The main script is intended for use in a scheduled task. It sets the dark-mode's and night-light's states according to the given times.\
Please note: The script that sets the dark-mode's state of the Windows OS changes the desktop's wallpaper to the default Windows light or dark wallpaper.

_Tested on Windows 11 (version 23H2, build 22631.2861)._

## How to Set the Scheduled Task?
1. Move the repository's content into a folder on your computer.
2. [Optional] Enable optional scripts by uncommenting the lines as you wish at the bottom of the [Set-DarkModeAndNightLightStates.ps1](Set-DarkModeAndNightLightStates.ps1) script.
3. Open PowerShell in the repository's folder and run the [Set-ScheduledTask.ps1](Set-ScheduledTask.ps1) script with the arguments described below:
    
    ```
    ./Set-ScheduledTask.ps1 DarkModeStartTime DarkModeEndTime NightLightStartTime NightLightEndTime
    ```
    
    Where:
    * _DarkModeStartTime_ [optional] - The time when dark-mode should start
    * _DarkModeEndTime_ [optional] - The time when dark-mode should end
    * _NightLightStartTime_ [optional] - The time when night-light should start
    * _NightLightEndTime_ [optional] - The time when night-light should end
    
    Example:
    * ```./Set-ScheduledTask.ps1 18:00 05:00 22:00 05:00```
    
Notes:
* If you move the repository's folder after you've already set the scheduled task, you will need to perform step #3 again.
* If you would like to change the dark-mode's/night-light's schedule, perform step #3 again, but with new values in arguments.
* If you would like to remove the scheduled task, perform step #3 again, but without arguments, and then answer "Y" to the prompt.
