<#
###############################################################################
# 
# Author: GTKrishna
# File: Disable-Teams-CloseButton.ps1
#
# Description:
# This PowerShell script launches Microsoft Teams and programmatically disables
# the window's close (X) button to prevent users from accidentally closing Teams.
#
# Key Functions:
# - Defines a function `_Disable-X` that calls Windows API methods from user32.dll
#   to manipulate system menus and disable the X button on a window.
# - Starts the Microsoft Teams process and waits until the main Teams window
#   handle is available (with a configurable timeout).
# - Once Teams is running, retrieves the window handle and applies `_Disable-X`
#   to disable the close button.
# - Provides timeout handling in case Teams does not launch within the expected time.
#
# Use Case:
# Ensures Microsoft Teams remains running by preventing accidental closure
# via the X button, which is useful in enterprise or kiosk environments.
#
# Category:
# PowerShell → Windows Automation → Process & UI Control
#
# Date: 15-10-2024
###############################################################################
#>


Function _Disable-X {
    #Calling user32.dll methods for Windows and Menus
    $MethodsCall = '
    [DllImport("user32.dll")] public static extern long GetSystemMenu(IntPtr hWnd, bool bRevert);
    [DllImport("user32.dll")] public static extern bool EnableMenuItem(long hMenuItem, long wIDEnableItem, long wEnable);
    [DllImport("user32.dll")] public static extern long SetWindowLongPtr(long hWnd, long nIndex, long dwNewLong);
    [DllImport("user32.dll")] public static extern bool EnableWindow(long hWnd, int bEnable);
    '
    $SC_CLOSE = 0xF060
    $MF_DISABLED = 0x00000002L
    #Create a new namespace for the Methods to be able to call them
    Add-Type -MemberDefinition $MethodsCall -name NativeMethods -namespace Win32

    #Get System menu of windows handled
    $hMenu = [Win32.NativeMethods]::GetSystemMenu($hwnd, 0)
    #Disable X Button
    [Win32.NativeMethods]::EnableMenuItem($hMenu, $SC_CLOSE, $MF_DISABLED) | Out-Null
}


# Start Microsoft Teams
Start-Process -File "$($env:USERProfile)\AppData\Local\Microsoft\Teams\current\Teams.exe" -PassThru | Out-Null
Start-Sleep -Seconds 10
# Set timeout (in seconds)
$timeout = 300  # Adjust the timeout duration as needed

# Get the current time
$startTime = Get-Date

# Loop until the Teams process is found or timeout is reached
while ((Get-Date) -lt ($startTime.AddSeconds($timeout)))
 {
$PSWindow = (Get-Process Teams) | where {$_.MainWindowTitle -like "*Teams*"}
$hwnd = $PSWindow.MainWindowHandle

if ($hWnd -ne $null) {
    Write-Host "Microsoft Teams process found with ID $($PSWindow.Id)."
    _Disable-X
    start-sleep -Seconds 3
    break  # Exit the loop if the process is found
} else {
    Write-Host "Microsoft Teams process not found."
    Start-Sleep -Seconds 5
}
}

# Check if the loop exited due to timeout
if ($hwnd -eq $null) {
    Write-Host "Timeout reached. Microsoft Teams process not found within the specified time."
}
