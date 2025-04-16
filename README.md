# StayActive PowerShell Script

**Disclaimer:** Using a script that simulates activity to avoid being marked as "away" or "AFK" on your computer may be against the policies of your organization or the services you're using. It is important to adhere to the rules and guidelines set by your employer or the platform you're using.

If you are looking to prevent your computer from entering sleep mode or locking the screen due to inactivity, you can simply adjust the power and sleep settings in Windows.

However, if you still want a simple PowerShell script to move the mouse cursor periodically, here it is. Please use it responsibly and only for legitimate purposes.

## Features
- Moves the mouse cursor minimally (1 pixel) to simulate activity
- Returns the cursor to its original position
- Configurable interval between movements (default: 60 seconds)
- Optional visual feedback in the console (can be disabled for long-running sessions)
- Proper error handling and clean termination

## How to Use
1. Open a text editor, such as **Notepad**.
2. Copy and paste the provided code into the text editor.
3. Save the file with the "**.ps1**" extension, for example, "**StayActive.ps1**".
4. **Right-click** on the saved file and select "**Run with PowerShell**".

The script will move the mouse cursor by 1 pixel and then move it back at the configured interval to simulate activity. To stop the script, press `Ctrl+C` in the PowerShell console or close the PowerShell window.

## Customization
You can adjust the following variables at the top of the script:
- `$moveInterval`: Time between movements in seconds (default: 60)
- `$smallMove`: Number of pixels to move (default: 1)
- `$showProgress`: Enable/disable progress dots in console (default: $true)
  - Set to `$false` for machines that need to run for days/weeks

## Reminder
Use this script responsibly and within the boundaries of the rules set by your organization or the services you are using.
