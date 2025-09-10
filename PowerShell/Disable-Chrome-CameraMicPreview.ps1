<#
###############################################################################
# Author: GTKrishna
# File: Disable-Chrome-CameraMicPreview.ps1
#
# Description:
# This PowerShell script enforces Chrome browser configuration by disabling 
# the "Camera and Mic Preview" experimental flag for the logged-in user. 
# It retrieves the active user context, modifies Chrome’s Local State JSON 
# configuration file, and ensures the flag is disabled. Logging and UI 
# prompts are included for audit and user visibility.
#
# Key functions:
# - Detects the current logged-in user (supports Azure AD / Workgroup).
# - Prevents unauthorized users from running the script.
# - Ensures Chrome is not running before modification.
# - Updates the Chrome "Local State" JSON file to disable the 
#   "camera-mic-preview@2" experimental flag.
# - Logs execution details to a transcript file.
# - Restarts Chrome after modification.
#
# Notes:
# - Must run in user context (modifies HKCU and AppData files).
# - Requires Chrome installed on the device.
# - Script logs are written to C:\Temp\Chrome-Disable-Camera-Mic-Log.txt
# - Uses registry and WMI queries for user resolution in AzureAD/Domain/Local.
#
# Date: 15-10-2024
###############################################################################
#>



# Set the execution policy to allow the script to run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

########Get-Username########
function Get-Username-on-System-Context {
    # Get Workgroup/AD User 
    $CurrentLoggedOnUser = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName)
    If ([String]::IsNullOrWhiteSpace($CurrentLoggedOnUser)) {
        $CurrentUser = Get-ItemProperty "Registry::\HKEY_USERS\*\Volatile Environment" | Where-Object { $_.USERDOMAIN -match 'AzureAD' -or $_.USERNAME -match 'WDAGUtilityAccount' }
        If (![String]::IsNullOrWhiteSpace($CurrentUser)) {
            $CurrentLoggedOnUser = "$($CurrentUser.USERDOMAIN)\$($CurrentUser.USERNAME)"
            $CurrentLoggedOnUserSID = Split-Path $CurrentUser.PSParentPath -Leaf
            If ($CurrentUser.USERDOMAIN -match 'AzureAD') {
                $UPNKeys = $(reg query hklm\SOFTWARE\Microsoft\IdentityStore\LogonCache /reg:64).Split([Environment]::NewLine) | Where-Object { $_ -ne "" }
                ForEach ($item in $UPNKeys) {
                    $UPN = reg @('query', "$item\Sid2Name\$CurrentLoggedOnUserSID", '/v', 'IdentityName', '/reg:64')
                    If ($LASTEXITCODE -eq 0) { $CurrentLoggedOnUserUPN = ($UPN[2] -split ' {2,}')[3]; Break }
                }
            }
        }
    }

    Write-Host "Current user: $CurrentLoggedOnUser"
    If (![string]::IsNullOrWhiteSpace($CurrentLoggedOnUserUPN)) { Write-Host "Current user UPN: $CurrentLoggedOnUserUPN" }
    return $CurrentLoggedOnUser
}

# Define the log file path
$logFilePath = "C:\Temp\Chrome-Disable-Camera-Mic-Log.txt"

# Start transcript
Start-Transcript -Path $logFilePath -Append

# Get the logged-in user
$username = Get-Username-on-System-Context

# Extract the domain from the username
$domain = $username.Split('\')[0]

# Check if the current user is the allowed user
if ($username -ne "$domain\USERNAME") {
    Write-Output "You do not have permission to run this script."
    [System.Windows.MessageBox]::Show("You do not have permission to run this script.")
    exit 1
}


if ($username) {
    Write-Output "Logged-in user: $username"

    # Extract the username from the domain\username format
    $username = $username.Split('\')[-1]

    # Define the path to the Chrome Local State file
    $localStatePath = "C:\Users\$username\AppData\Local\Google\Chrome\User Data\Local State"

    # Ensure Chrome is not running
    Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue

    # Read the Local State file
    if (Test-Path $localStatePath) {
        $localState = Get-Content $localStatePath -Raw | ConvertFrom-Json

        # Log the raw Local State file content
        Write-Output "Raw Local State file content: $($localState | ConvertTo-Json -Depth 100)"

        # Check if the "browser" key exists
        if (-not $localState.browser) {
            $localState | Add-Member -MemberType NoteProperty -Name "browser" -Value @{ }
        }

        # Check if the "enabled_labs_experiments" key exists within the "browser" object
        if (-not $localState.browser.PSObject.Properties["enabled_labs_experiments"]) {
            $localState.browser | Add-Member -MemberType NoteProperty -Name "enabled_labs_experiments" -Value @()
        }

        # Disable the "Camera and Mic Preview" flag
        $flag = "camera-mic-preview@2"
        if ($localState.browser.enabled_labs_experiments -contains $flag) {
            $localState.browser.enabled_labs_experiments = $localState.browser.enabled_labs_experiments | Where-Object { $_ -ne $flag }
        }

        # Ensure the flag is not in the enabled_labs_experiments array
        if (-not ($localState.browser.enabled_labs_experiments -contains $flag)) {
            $localState.browser.enabled_labs_experiments += $flag
        }

        # Write the modified Local State back to the file
        $localState | ConvertTo-Json -Depth 100 | Set-Content $localStatePath -Force

        Write-Output "Camera and Mic Preview flag has been disabled."
        [System.Windows.MessageBox]::Show("Camera and Mic Preview flag has been disabled.")
    } else {
        Write-Output "Chrome Local State file not found."
        [System.Windows.MessageBox]::Show("Chrome Local State file not found,Check whether Chrome is installed")
    }

    # Restart Chrome
    Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe"
} else {
    Write-Output "No logged-in user found."
    [System.Windows.MessageBox]::Show("No logged-in user found.")
}

# Stop transcript
Stop-Transcript
