# StayActive.ps1
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Mouse {
    [DllImport("user32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo);
}
"@ -Language CSharp

$MOUSEEVENTF_MOVE = 0x0001

while ($true) {
    [Mouse]::mouse_event($MOUSEEVENTF_MOVE, 1, 1, 0, 0)
    Start-Sleep -s 1
    [Mouse]::mouse_event($MOUSEEVENTF_MOVE, 4294967295, 4294967295, 0, 0)
    Start-Sleep -m 4
}
