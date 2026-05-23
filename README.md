# StayActive PowerShell Script

**Disclaimer:** Using a script that simulates activity or overrides power policy to avoid being marked as "away" or "AFK" on your computer may be against the policies of your organization or the services you're using. Please follow the rules and guidelines set by your employer or the platform you're using.

If you just want to prevent your computer from entering sleep mode or locking the screen due to inactivity, you can also adjust the power and sleep settings in Windows directly.

However, if you still want a small PowerShell script that either keeps Windows awake or periodically nudges the mouse, here it is. Use it responsibly and only for legitimate purposes.

## Two Modes

StayActive offers two distinct ways to keep a Windows machine marked active:

- **KeepAwake mode** signals Windows via `SetThreadExecutionState` so the OS will not enter system or display sleep while the script runs. This is the official power-management API and is ideal for presentations, long downloads, file copies, or remote sessions. It does *not* influence applications that track user input (such as Microsoft Teams presence), because it is a power-management hint, not input.
- **Nudge mode** (the default) periodically moves the mouse cursor by one pixel and moves it back. This is what most "presence" features actually detect. Combine with `-OnlyWhenIdle` to avoid interrupting active work; the script will then only nudge after the system has been idle for a configurable threshold.

Pick KeepAwake when you only care about the machine, and Nudge when you care about how an app perceives you.

## Quick Start

1. **Download** the signed script from the [latest release](https://github.com/virtualox/StayActive.ps1/releases/latest/download/StayActive.ps1) (digitally signed with an EV code signing certificate, Sectigo-timestamped)
2. **Run**: Right-click the file and select "Run with PowerShell", or use the PowerShell command line
3. **Stop**: Press `Ctrl+C` in the PowerShell window

Or download from a PowerShell prompt:

```powershell
Invoke-WebRequest -Uri 'https://github.com/virtualox/StayActive.ps1/releases/latest/download/StayActive.ps1' -OutFile StayActive.ps1
```

## Command-Line Usage

### Basic Syntax

```powershell
.\StayActive.ps1 [-MoveInterval <seconds>] [-SmallMove <pixels>] [-OnlyWhenIdle] [-IdleSeconds <seconds>] [-ShowProgress] [-Verbose]
.\StayActive.ps1 -KeepAwake [-KeepDisplay] [-ShowProgress] [-Verbose]
```

Get full help any time with:

```powershell
Get-Help .\StayActive.ps1 -Full
```

### Parameters

#### Nudge mode (default)

| Parameter        | Type    | Default | Description                                                                 |
|------------------|---------|---------|-----------------------------------------------------------------------------|
| `-MoveInterval`  | Integer | 60      | Seconds between mouse nudges                                                |
| `-SmallMove`     | Integer | 1       | Pixels to move the cursor in each direction (1-10)                          |
| `-OnlyWhenIdle`  | Switch  | Off     | Only nudge when the user has been idle long enough                          |
| `-IdleSeconds`   | Integer | 60      | Idle threshold for `-OnlyWhenIdle`                                          |
| `-ShowProgress`  | Switch  | Off     | Print a one-line status after each cycle                                    |

#### KeepAwake mode

| Parameter        | Type    | Default | Description                                                                 |
|------------------|---------|---------|-----------------------------------------------------------------------------|
| `-KeepAwake`     | Switch  | Off     | Use `SetThreadExecutionState` to keep the system awake                      |
| `-KeepDisplay`   | Switch  | Off     | Also keep the display on (adds `ES_DISPLAY_REQUIRED`)                       |
| `-ShowProgress`  | Switch  | Off     | Print a one-line status after each heartbeat                                |

`-Verbose` is supported in both modes and prints a per-cycle countdown using `Write-Progress`.

### Usage Examples

```powershell
# Default Nudge mode: 1 pixel every 60 seconds
.\StayActive.ps1

# Keep the system awake (presentation, large download)
.\StayActive.ps1 -KeepAwake

# Keep the system AND the display awake
.\StayActive.ps1 -KeepAwake -KeepDisplay

# Nudge, but only when the user has actually walked away
.\StayActive.ps1 -OnlyWhenIdle -IdleSeconds 120 -ShowProgress

# Faster cadence with progress indicator
.\StayActive.ps1 -MoveInterval 30 -ShowProgress

# Detailed countdown via Write-Progress
.\StayActive.ps1 -Verbose
```

## Output Examples

### Standard Mode

```
============================================================
StayActive started in Nudge mode
============================================================
Start time: 2026-05-23 14:30:15
Move interval: 60 seconds
Move distance: 1 pixel(s)

Press Ctrl+C to stop.
============================================================
```

### Progress Mode

```
[14:31:15] moved (#1) | runtime 00:01:00 | next in 60 s
[14:32:15] moved (#2) | runtime 00:02:00 | next in 60 s
```

### OnlyWhenIdle Mode

```
[14:31:15] skipped (user active) | runtime 00:01:00 | next in 60 s
[14:32:15] moved (#1) | runtime 00:02:00 | next in 60 s
```

### Termination Summary

```
============================================================
StayActive stopped
============================================================
End time:      2026-05-23 15:30:15
Total runtime: 01:00:00
Mouse nudges:  60
Average gap:   60 seconds
============================================================
```

## How It Works

- **Native API:** Mouse input is synthesized via `SendInput` from `user32.dll`. This is the modern replacement for the older `mouse_event` API. Idle detection uses `GetLastInputInfo`.
- **Power management:** KeepAwake mode calls `SetThreadExecutionState` with `ES_CONTINUOUS | ES_SYSTEM_REQUIRED`, optionally combined with `ES_DISPLAY_REQUIRED`. The flag is cleared automatically when the script exits.
- **Idempotent interop:** The C# interop type is defined once per PowerShell session, so re-running the script in the same session works without errors.
- **Output streams:** Status output uses `Write-Information` (the Information stream) and `Write-Progress`, which means it can be redirected, suppressed, or captured like any other PowerShell stream.

## System Requirements

- Windows 10 or 11 (any Windows version with `user32.dll` and `kernel32.dll`)
- Windows PowerShell 5.1, or PowerShell 7+ on Windows
- PowerShell running in `FullLanguage` mode. If you are running under AppLocker, WDAC, or another policy that forces Constrained Language Mode, the script will exit early with an explanatory message because `Add-Type` cannot compile C# in that mode.
- An execution policy that allows local scripts (`RemoteSigned`, `Bypass`, or signed by a trusted publisher)

The script explicitly checks `$IsWindows` on PowerShell 7. Running it on macOS or Linux fails fast with a pointer to `caffeinate` or `systemd-inhibit` instead of crashing later.

## Troubleshooting

### Script will not run (Execution Policy)

```powershell
# Check the current policy
Get-ExecutionPolicy

# Allow scripts for the current session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### "PowerShell is running in ConstrainedLanguage mode"

Your environment is locked down by AppLocker or WDAC. Ask your administrator for an exemption, or run the script from a host that is not subject to the policy.

### KeepAwake mode does not prevent Teams from marking me away

That is intentional. KeepAwake is a power-management signal to Windows, not a synthetic input event. Use Nudge mode (the default) when an application's "presence" feature is what you care about.

### Nudge mode interrupts my work

Use `-OnlyWhenIdle` together with `-IdleSeconds`. The script will then only move the cursor after you have actually stopped using the mouse and keyboard.

## Responsible Usage

- **Respect organizational policies** regarding computer activity simulation and power management overrides.
- **Use only for legitimate purposes** such as preventing screen lock during a presentation or keeping a long-running job alive.
- **Be transparent** with your IT department if you use this in a corporate environment.
- **Consider alternatives first**: adjusting Windows power settings, using `presentationsettings.exe`, or using Windows' built-in presentation mode.

## License

This project is licensed under the **GPL-3.0 License** - see the [LICENSE](LICENSE) file for details.

This script is provided as-is for educational and legitimate use purposes. Users are responsible for ensuring compliance with their organization's policies and applicable laws.

## Contributing

Feel free to submit issues and enhancement requests. When contributing:

1. Keep the script working on Windows PowerShell 5.1 as well as PowerShell 7+
2. Add `ValidateRange` / `ValidateSet` attributes to new parameters
3. Update the comment-based help block in `StayActive.ps1` for any new parameters
4. Update this README's parameter tables and examples
5. Test under both Nudge and KeepAwake modes before submitting
