#Requires -Version 5.1

<#
.SYNOPSIS
    Keeps a Windows machine awake or marked as active.

.DESCRIPTION
    StayActive offers two modes:

    KeepAwake mode signals the OS via SetThreadExecutionState so Windows will not
    enter system or display sleep while the script runs. This is the recommended
    way to keep a machine awake during presentations, long downloads, or remote
    sessions. It does not influence applications that track user input (such as
    Microsoft Teams presence) because it is a power-management hint, not input.

    Nudge mode (the default) periodically moves the mouse cursor by one pixel and
    moves it back. This is what most "presence" features detect. Combine with
    -OnlyWhenIdle to avoid interrupting the user; the script will only nudge
    after the system has been idle for -IdleSeconds.

    Press Ctrl+C to stop. The script clears any execution-state flag it set
    during shutdown.

.PARAMETER KeepAwake
    Use SetThreadExecutionState to keep the system awake. Combine with
    -KeepDisplay to also prevent the display from turning off.

.PARAMETER KeepDisplay
    Only valid with -KeepAwake. Adds ES_DISPLAY_REQUIRED so the screen stays on.

.PARAMETER MoveInterval
    Seconds between mouse nudges in Nudge mode. Default: 60.

.PARAMETER SmallMove
    Pixels to move the cursor in each direction in Nudge mode. The cursor is
    moved by this amount and then moved back. Default: 1.

.PARAMETER OnlyWhenIdle
    In Nudge mode, only move the mouse if the user has been idle for at least
    -IdleSeconds. Avoids interrupting active work.

.PARAMETER IdleSeconds
    Idle threshold for -OnlyWhenIdle. Default: 60.

.PARAMETER ShowProgress
    Print a short status line each cycle.

.EXAMPLE
    .\StayActive.ps1

    Default Nudge mode: moves the mouse 1 pixel every 60 seconds.

.EXAMPLE
    .\StayActive.ps1 -KeepAwake -KeepDisplay

    Asks Windows to keep the system and display awake. No mouse input is
    simulated.

.EXAMPLE
    .\StayActive.ps1 -OnlyWhenIdle -IdleSeconds 120 -ShowProgress

    Nudges the mouse, but only when the user has been idle for two minutes.

.INPUTS
    None. This script does not accept pipeline input.

.OUTPUTS
    None. Status output is written to the Information stream.

.NOTES
    Version : 4.0.0
    License : GPL-3.0

    Using a script to simulate user activity or to override power policy may
    violate your employer's or service provider's policies. Use responsibly.

.LINK
    https://github.com/virtualox/StayActive.ps1
#>

[CmdletBinding(DefaultParameterSetName = 'Nudge')]
param(
    [Parameter(ParameterSetName = 'KeepAwake')]
    [switch]$KeepAwake,

    [Parameter(ParameterSetName = 'KeepAwake')]
    [switch]$KeepDisplay,

    [Parameter(ParameterSetName = 'Nudge')]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$MoveInterval = 60,

    [Parameter(ParameterSetName = 'Nudge')]
    [ValidateRange(1, 10)]
    [int]$SmallMove = 1,

    [Parameter(ParameterSetName = 'Nudge')]
    [switch]$OnlyWhenIdle,

    [Parameter(ParameterSetName = 'Nudge')]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$IdleSeconds = 60,

    [switch]$ShowProgress
)

# Route Write-Information output to the host while the script runs.
$InformationPreference = 'Continue'

# Platform guard. PowerShell 7 also runs on macOS and Linux, where user32.dll
# does not exist; fail fast with a helpful pointer.
$onWindows = $true
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $onWindows = $IsWindows
}
if (-not $onWindows) {
    Write-Error 'StayActive requires Windows. On macOS use "caffeinate"; on Linux use "systemd-inhibit" or "xdg-screensaver".'
    exit 1
}

# Constrained Language Mode (AppLocker, WDAC) blocks Add-Type's C# compilation.
if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    Write-Error "PowerShell is running in $($ExecutionContext.SessionState.LanguageMode) mode; StayActive needs FullLanguage. Ask your administrator for an AppLocker or WDAC exemption, or run from a less restricted host."
    exit 1
}

# Define the native interop once per session. CLR types cannot be unloaded,
# so re-running the script in the same session must not redefine them.
if (-not ('StayActive.NativeMethods' -as [type])) {
    Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace StayActive {
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT {
        public int    dx;
        public int    dy;
        public uint   mouseData;
        public uint   dwFlags;
        public uint   time;
        public IntPtr dwExtraInfo;
    }

    // INPUT is officially a union of MOUSEINPUT / KEYBDINPUT / HARDWAREINPUT.
    // We only send mouse input, and MOUSEINPUT is the largest member, so a
    // sequential layout with just MOUSEINPUT marshals to the correct size on
    // both x86 and x64 (Marshal.SizeOf is used at the call site).
    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT {
        public uint       type;
        public MOUSEINPUT mi;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    public static class NativeMethods {
        public const uint INPUT_MOUSE         = 0;
        public const uint MOUSEEVENTF_MOVE    = 0x0001;

        public const uint ES_CONTINUOUS       = 0x80000000;
        public const uint ES_SYSTEM_REQUIRED  = 0x00000001;
        public const uint ES_DISPLAY_REQUIRED = 0x00000002;

        [DllImport("user32.dll", SetLastError = true)]
        public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetCursorPos(out POINT lpPoint);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern uint SetThreadExecutionState(uint esFlags);

        [DllImport("kernel32.dll")]
        public static extern uint GetTickCount();
    }
}
'@
}

function Get-MousePosition {
    $point = New-Object StayActive.POINT
    if (-not [StayActive.NativeMethods]::GetCursorPos([ref]$point)) {
        $code = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "GetCursorPos failed (Win32 error $code)."
    }
    return $point
}

function Get-IdleSeconds {
    $info = New-Object StayActive.LASTINPUTINFO
    $info.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($info)
    if (-not [StayActive.NativeMethods]::GetLastInputInfo([ref]$info)) {
        $code = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "GetLastInputInfo failed (Win32 error $code)."
    }
    $tickDelta = [StayActive.NativeMethods]::GetTickCount() - $info.dwTime
    return [int]($tickDelta / 1000)
}

function Move-MouseNudge {
    param([int]$Delta)

    $forward = New-Object StayActive.INPUT
    $forward.type = [StayActive.NativeMethods]::INPUT_MOUSE
    $forward.mi.dx = $Delta
    $forward.mi.dy = $Delta
    $forward.mi.dwFlags = [StayActive.NativeMethods]::MOUSEEVENTF_MOVE

    $back = New-Object StayActive.INPUT
    $back.type = [StayActive.NativeMethods]::INPUT_MOUSE
    $back.mi.dx = -$Delta
    $back.mi.dy = -$Delta
    $back.mi.dwFlags = [StayActive.NativeMethods]::MOUSEEVENTF_MOVE

    $size = [System.Runtime.InteropServices.Marshal]::SizeOf([type][StayActive.INPUT])
    [StayActive.NativeMethods]::SendInput(1, @($forward), $size) | Out-Null
    Start-Sleep -Milliseconds 100
    [StayActive.NativeMethods]::SendInput(1, @($back), $size) | Out-Null
}

function Write-Banner {
    param([string]$Title)
    Write-Information ('=' * 60)
    Write-Information $Title
    Write-Information ('=' * 60)
}

$mode             = $PSCmdlet.ParameterSetName
$verboseRequested = $PSBoundParameters.ContainsKey('Verbose')
$startTime        = Get-Date
$moveCount        = 0
$executionStateSet = $false

Write-Banner -Title "StayActive started in $mode mode"
Write-Information "Start time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

if ($mode -eq 'KeepAwake') {
    $flags = [StayActive.NativeMethods]::ES_CONTINUOUS -bor [StayActive.NativeMethods]::ES_SYSTEM_REQUIRED
    if ($KeepDisplay) {
        $flags = $flags -bor [StayActive.NativeMethods]::ES_DISPLAY_REQUIRED
    }
    $previous = [StayActive.NativeMethods]::SetThreadExecutionState($flags)
    if ($previous -eq 0) {
        throw 'SetThreadExecutionState failed.'
    }
    $executionStateSet = $true
    Write-Information "Display kept on: $KeepDisplay"
} else {
    Write-Information "Move interval: $MoveInterval seconds"
    Write-Information "Move distance: $SmallMove pixel(s)"
    if ($OnlyWhenIdle) {
        Write-Information "Idle guard:    only nudge after $IdleSeconds seconds of inactivity"
    }
}

Write-Information ''
Write-Information 'Press Ctrl+C to stop.'
Write-Information ('=' * 60)

try {
    while ($true) {
        if ($mode -eq 'KeepAwake') {
            # The OS resets the system-idle timer on every SetThreadExecutionState
            # call with ES_CONTINUOUS, so a 60-second heartbeat is plenty. Sleeping
            # avoids burning CPU on a busy-loop.
            Start-Sleep -Seconds 60
            continue
        }

        $shouldMove = $true
        if ($OnlyWhenIdle) {
            $idle = Get-IdleSeconds
            Write-Verbose "User has been idle for $idle second(s)."
            if ($idle -lt $IdleSeconds) {
                $shouldMove = $false
            }
        }

        if ($shouldMove) {
            try {
                $pos = Get-MousePosition
                Write-Verbose "Current mouse position: X=$($pos.X), Y=$($pos.Y)"
            } catch {
                Write-Warning $_.Exception.Message
            }
            Move-MouseNudge -Delta $SmallMove
            $moveCount++
        }

        if ($ShowProgress) {
            $stamp   = Get-Date -Format 'HH:mm:ss'
            $runtime = '{0:hh\:mm\:ss}' -f ((Get-Date) - $startTime)
            $action  = if ($shouldMove) { "moved (#$moveCount)" } else { 'skipped (user active)' }
            Write-Information "[$stamp] $action | runtime $runtime | next in $MoveInterval s"
        }

        if ($verboseRequested -and $MoveInterval -gt 5) {
            for ($remaining = $MoveInterval; $remaining -gt 0; $remaining--) {
                Write-Progress -Activity 'StayActive' -Status "Next cycle in $remaining s" -SecondsRemaining $remaining
                Start-Sleep -Seconds 1
            }
            Write-Progress -Activity 'StayActive' -Completed
        } else {
            Start-Sleep -Seconds $MoveInterval
        }
    }
} catch {
    if ($_.Exception -isnot [System.Management.Automation.PipelineStoppedException]) {
        Write-Error $_
    }
} finally {
    if ($executionStateSet) {
        [StayActive.NativeMethods]::SetThreadExecutionState([StayActive.NativeMethods]::ES_CONTINUOUS) | Out-Null
    }

    Write-Progress -Activity 'StayActive' -Completed -ErrorAction SilentlyContinue
    $totalRuntime = (Get-Date) - $startTime
    Write-Banner -Title 'StayActive stopped'
    Write-Information "End time:      $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Information "Total runtime: $('{0:hh\:mm\:ss}' -f $totalRuntime)"
    if ($mode -eq 'Nudge') {
        Write-Information "Mouse nudges:  $moveCount"
        if ($moveCount -gt 0) {
            $avg = [math]::Round($totalRuntime.TotalSeconds / $moveCount, 1)
            Write-Information "Average gap:   $avg seconds"
        }
    }
    Write-Information ('=' * 60)
}
