# StayActive PowerShell Script

**Disclaimer:** Using a script that simulates activity to avoid being marked as "away" or "AFK" on your computer may be against the policies of your organization or the services you're using. It is important to adhere to the rules and guidelines set by your employer or the platform you're using.

If you are looking to prevent your computer from entering sleep mode or locking the screen due to inactivity, you can simply adjust the power and sleep settings in Windows.

However, if you still want a simple PowerShell script to move the mouse cursor periodically, here it is. Please use it responsibly and only for legitimate purposes.

## Features

- **Minimal Mouse Movement**: Moves the mouse cursor by a configurable number of pixels (default: 1 pixel) and returns it to the original position
- **Configurable Timing**: Adjustable interval between movements (default: 60 seconds)
- **Command-Line Parameters**: Full parameter support for easy customization
- **Progress Indicators**: Optional visual feedback showing current time, movement count, and runtime
- **Verbose Logging**: Detailed logging with timestamps for troubleshooting and monitoring
- **Enhanced Error Handling**: Graceful termination and comprehensive error reporting
- **Usage Statistics**: Summary of runtime and movement statistics on exit
- **Built-in Help**: Comprehensive help system with usage examples

## Quick Start

1. **Download**: Save the script as `StayActive.ps1`
2. **Run**: Right-click the file and select "Run with PowerShell", or use PowerShell command line
3. **Stop**: Press `Ctrl+C` in the PowerShell window

## Command-Line Usage

### Basic Syntax
```powershell
.\StayActive.ps1 [-MoveInterval <seconds>] [-SmallMove <pixels>] [-ShowProgress] [-Verbose] [-Help]
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-MoveInterval` | Integer | 60 | Time between movements in seconds |
| `-SmallMove` | Integer | 1 | Number of pixels to move (1-10) |
| `-ShowProgress` | Switch | Off | Show progress indicators in console |
| `-Verbose` | Switch | Off | Enable detailed logging with timestamps |
| `-Help` | Switch | Off | Display help information and exit |

### Usage Examples

```powershell
# Basic usage with default settings (60-second interval)
.\StayActive.ps1

# Show progress indicators
.\StayActive.ps1 -ShowProgress

# Custom interval with progress
.\StayActive.ps1 -MoveInterval 30 -ShowProgress

# Verbose logging for detailed monitoring
.\StayActive.ps1 -Verbose

# Custom settings with all features
.\StayActive.ps1 -MoveInterval 45 -SmallMove 2 -ShowProgress -Verbose

# Quick 30-second intervals for testing
.\StayActive.ps1 -MoveInterval 30 -ShowProgress -Verbose

# Display help and usage information
.\StayActive.ps1 -Help
```

## Output Examples

### Standard Mode
```
============================================================
StayActive Enhanced Script Started
============================================================
Start Time:     2024-12-07 14:30:15
Move Interval:  60 seconds
Move Distance:  1 pixel(s)
Show Progress:  False
Verbose Mode:   False

Press Ctrl+C to stop the script
============================================================
```

### Progress Mode
```
[14:31:15] Move #1 | Runtime: 00:01:00 | Next in: 60 sec
[14:32:15] Move #2 | Runtime: 00:02:00 | Next in: 60 sec
```

### Verbose Mode
```
[2024-12-07 14:30:16] Script initialization completed
[2024-12-07 14:30:16] Current mouse position: X=960, Y=540
[2024-12-07 14:30:16] Moving mouse 1 pixel(s) right/down
[2024-12-07 14:30:16] Moving mouse back to original position
[2024-12-07 14:30:16] Movement cycle #1 completed. Total runtime: 00:00:01
```

## Advanced Features

### Parameter Validation
- Move interval must be at least 1 second
- Small move distance must be between 1-10 pixels
- Invalid parameters show helpful error messages

### Error Handling
- Graceful handling of Ctrl+C interruption
- Detailed error reporting in verbose mode
- Clean script termination with summary statistics

### Runtime Statistics
Upon termination, the script displays:
- Total runtime
- Number of movements performed
- Average interval between movements

## Installation Methods

### Method 1: Direct Download and Run
1. Save the script content to a file named `StayActive.ps1`
2. Right-click the file and select "Run with PowerShell"

### Method 2: PowerShell Command Line
1. Open PowerShell in the script directory
2. Run: `.\StayActive.ps1` with desired parameters

### Method 3: PowerShell with Execution Policy
If you encounter execution policy restrictions:
```powershell
# Temporarily allow script execution
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\StayActive.ps1
```

## Troubleshooting

### Common Issues

**Script won't run (Execution Policy)**
```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

**Need more detailed information**
- Use the `-Verbose` parameter for detailed logging
- Use the `-Help` parameter for usage information

**Script running too frequently/infrequently**
- Adjust the `-MoveInterval` parameter (minimum 1 second)
- Use `-ShowProgress` to monitor timing

## System Requirements

- Windows PowerShell 5.1 or PowerShell Core 6.0+
- Windows operating system with user32.dll (standard on all Windows versions)
- Appropriate execution policy or administrator privileges to run scripts

## Technical Details

The script uses Windows API calls to:
- Move the mouse cursor using `mouse_event` function
- Track cursor position with `GetCursorPos` function
- Ensure minimal system impact with precise pixel movements

## Responsible Usage

- **Respect organizational policies** regarding computer activity simulation
- **Use only for legitimate purposes** such as preventing screen lock during presentations
- **Be transparent** with your IT department if using in corporate environments
- **Consider alternatives** like adjusting Windows power settings first

## License

This project is licensed under the **GPL-3.0 License** - see the [LICENSE](LICENSE) file for details.

This script is provided as-is for educational and legitimate use purposes. Users are responsible for ensuring compliance with their organization's policies and applicable laws.

## Contributing

Feel free to submit issues and enhancement requests. When contributing:
1. Ensure backward compatibility
2. Add appropriate parameter validation
3. Include help documentation for new features
4. Test thoroughly on different Windows versions
