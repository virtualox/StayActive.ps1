#Requires -Version 5.1

# StayActive.ps1
# This script keeps your computer active by minimally moving the mouse cursor
# Features: Command-line parameters, verbose logging, enhanced progress indicators
# To stop: press Ctrl+C in the PowerShell window

[CmdletBinding()]
param(
    [Parameter(HelpMessage="Time between movements in seconds (default: 60)")]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$MoveInterval = 60,

    [Parameter(HelpMessage="Number of pixels to move (default: 1)")]
    [ValidateRange(1, 10)]
    [int]$SmallMove = 1,

    [Parameter(HelpMessage="Show progress indicators in console")]
    [switch]$ShowProgress,

    [Parameter(HelpMessage="Show this help message")]
    [switch]$Help
)

# Show help if requested
if ($Help) {
    Write-Host @"
StayActive.ps1 - Mouse Movement Activity Simulator

USAGE:
    .\StayActive.ps1 [-MoveInterval <seconds>] [-SmallMove <pixels>] [-ShowProgress] [-Verbose] [-Help]

PARAMETERS:
    -MoveInterval <int>    Time between movements in seconds (default: 60)
    -SmallMove <int>       Number of pixels to move (default: 1)
    -ShowProgress          Show progress indicators in console
    -Verbose               Enable detailed logging with timestamps
    -Help                  Show this help message

EXAMPLES:
    .\StayActive.ps1
    .\StayActive.ps1 -MoveInterval 30 -ShowProgress
    .\StayActive.ps1 -MoveInterval 120 -SmallMove 2 -Verbose
    .\StayActive.ps1 -ShowProgress -Verbose

NOTES:
    - Use responsibly and within your organization's policies
    - Press Ctrl+C to stop the script
    - The script moves the mouse minimally and returns it to original position
"@
    exit 0
}

# Import the required Windows API function
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Mouse {
    [DllImport("user32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo);
    
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
}

public struct POINT {
    public int X;
    public int Y;
}
"@ -Language CSharp

# Define constants
$MOUSEEVENTF_MOVE = 0x0001

# Function to write verbose log messages
function Write-DetailedLog {
    param([string]$Message)
    Write-Verbose "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

# Function to get current mouse position
function Get-MousePosition {
    $point = New-Object POINT
    [Mouse]::GetCursorPos([ref]$point) | Out-Null
    return $point
}

# Display startup information
$startTime = Get-Date
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host "StayActive Enhanced Script Started" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host "Start Time:     $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Move Interval:  $MoveInterval seconds"
Write-Host "Move Distance:  $SmallMove pixel(s)"
Write-Host "Show Progress:  $ShowProgress"
Write-Host "Verbose Mode:   $($VerbosePreference -ne 'SilentlyContinue')"
Write-Host ""
Write-Host "Press Ctrl+C to stop the script" -ForegroundColor Yellow
Write-Host ("=" * 60) -ForegroundColor Green

Write-DetailedLog "Script initialization completed"
Write-DetailedLog "Windows API functions loaded successfully"

# Initialize counters
$moveCount = 0
$totalRunTime = 0

try {
    while ($true) {
        $cycleStartTime = Get-Date
        
        # Get initial mouse position for logging
        $initialPos = Get-MousePosition
        Write-DetailedLog "Current mouse position: X=$($initialPos.X), Y=$($initialPos.Y)"
        
        # Move the mouse right/down
        Write-DetailedLog "Moving mouse $SmallMove pixel(s) right/down"
        [Mouse]::mouse_event($MOUSEEVENTF_MOVE, $SmallMove, $SmallMove, 0, 0)
        Start-Sleep -Milliseconds 100
        
        # Move the mouse back (using negative coordinates via uint conversion)
        Write-DetailedLog "Moving mouse back to original position"
        $negativeMove = [uint32]::MaxValue - $SmallMove + 1
        [Mouse]::mouse_event($MOUSEEVENTF_MOVE, $negativeMove, $negativeMove, 0, 0)
        
        # Update counters
        $moveCount++
        $totalRunTime = (Get-Date) - $startTime
        
        # Show progress information
        if ($ShowProgress -or ($VerbosePreference -ne 'SilentlyContinue')) {
            $currentTime = Get-Date -Format "HH:mm:ss"
            $runtime = "{0:hh\:mm\:ss}" -f $totalRunTime
            
            if ($ShowProgress -and ($VerbosePreference -eq 'SilentlyContinue')) {
                # Compact progress indicator for non-verbose mode
                Write-Host "[$currentTime] Move #$moveCount | Runtime: $runtime | Next in: $MoveInterval sec" -ForegroundColor Green
            }
        }
        
        Write-DetailedLog "Movement cycle #$moveCount completed. Total runtime: $("{0:hh\:mm\:ss}" -f $totalRunTime)"
        Write-DetailedLog "Waiting $MoveInterval seconds until next movement..."
        
        # Wait until the next movement with countdown if verbose
        if ($VerbosePreference -ne 'SilentlyContinue') {
            for ($i = $MoveInterval; $i -gt 0; $i--) {
                if ($i % 10 -eq 0 -or $i -le 5) {
                    Write-DetailedLog "Next movement in $i seconds..."
                }
                Start-Sleep -Seconds 1
            }
        } else {
            Start-Sleep -Seconds $MoveInterval
        }
    }
}
catch [System.Management.Automation.PipelineStoppedException] {
    # Handle Ctrl+C gracefully
    Write-Host "`n" -NoNewline
}
catch {
    Write-Host "`nScript stopped due to error: $_" -ForegroundColor Red
    Write-DetailedLog "Error details: $($_.Exception.Message)"
}
finally {
    # Display summary information
    $endTime = Get-Date
    $totalRunTime = $endTime - $startTime
    
    Write-Host ("`n" + ("=" * 60)) -ForegroundColor Red
    Write-Host "StayActive Script Terminated" -ForegroundColor Red
    Write-Host ("=" * 60) -ForegroundColor Red
    Write-Host "End Time:           $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "Total Runtime:      $("{0:hh\:mm\:ss}" -f $totalRunTime)"
    Write-Host "Total Movements:    $moveCount"
    if ($moveCount -gt 0) {
        Write-Host "Average Interval:   $([math]::Round($totalRunTime.TotalSeconds / $moveCount, 1)) seconds"
    }
    Write-Host ("=" * 60) -ForegroundColor Red
    
    Write-DetailedLog "Script cleanup completed"
}
