# StayActive.ps1
# This script keeps your computer active by minimally moving the mouse cursor
# It moves the cursor 1 pixel right/down and then 1 pixel back
# To stop: press Ctrl+C in the PowerShell window

# Configuration
$moveInterval = 60  # Time between movements in seconds
$smallMove = 1      # Number of pixels to move
$showProgress = $true  # Show progress dots in console

# Import the required Windows API function
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Mouse {
    [DllImport("user32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo);
}
"@ -Language CSharp

# Define the constant for mouse movement
$MOUSEEVENTF_MOVE = 0x0001

# Display information at startup
Write-Host "StayActive script has started. Press Ctrl+C to stop."
Write-Host "The mouse will move minimally every $moveInterval seconds."
if ($showProgress) {
    Write-Host "Progress indicator is enabled. Dots will show activity."
} else {
    Write-Host "Progress indicator is disabled. No visual feedback will be shown."
}

try {
    while ($true) {
        # Move the mouse right/down
        [Mouse]::mouse_event($MOUSEEVENTF_MOVE, $smallMove, $smallMove, 0, 0)
        Start-Sleep -Milliseconds 100
        
        # Move the mouse back (with negative coordinates)
        # Note: In uint, -1 is interpreted as 4294967295
        [Mouse]::mouse_event($MOUSEEVENTF_MOVE, [uint32]::MaxValue, [uint32]::MaxValue, 0, 0)
        
        # Wait until the next movement
        if ($showProgress) {
            Write-Host "." -NoNewline
        }
        Start-Sleep -Seconds $moveInterval
    }
}
catch {
    Write-Host "`nScript stopped: $_"
}
finally {
    Write-Host "`nStayActive script has terminated."
}
