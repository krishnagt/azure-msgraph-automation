<#
###############################################################################
# 
# Author: GTKrishna
# File: Get-Intune-Device-Sync-Status.ps1
#
# Description:
# This PowerShell script connects to Microsoft Graph API using client credentials
# and generates a device sync status report for Intune-managed Windows 10 devices.
#
# Key Functions:
# - Authenticates with Microsoft Graph using ClientId, TenantId, and ClientSecret.
# - Identifies Azure AD groups that match the naming pattern '*-W10'.
# - For each device in those groups, retrieves details such as:
#     • Device name
#     • Last sync time
#     • Sync status (in sync / not in sync within last 24 hrs)
#     • Enrollment date
#     • Compliance state
#     • Join type
#     • Azure AD registration status
# - Exports results to a CSV report:
#     C:\Temp\device_sync_status_report.csv
#
# Use Case:
# Provides Intune administrators with quick visibility into device compliance
# and sync health, enabling proactive troubleshooting and reporting.
#
# Date: 15-10-2024
###############################################################################
#>



Function Intune-Device-Sync-status()
{
    param (
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$ClientId,
        [Parameter(Mandatory = $True, Position = 2)]
        [string]$TenantId,
        [Parameter(Mandatory = $True, Position = 3)]
        [string]$ClientSecret
    )


# Convert the client secret to a secure string
$pass = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force

# Create a credential object using the client ID and secure string
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $pass

# Connect to Microsoft Graph with Client Secret
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $cred

$deviceHash = @()
    $today1 = Get-Date
    $date2 = $today1.DateTime

    # Get all groups that end with '-W10'
    $allGroups = Get-MgGroup -All
    $groups = $allGroups | Where-Object { $_.DisplayName -match 'DEVICE-W10' }

    if ($groups.Count -eq 0) {
        Write-Host "No groups found ending with '-W10'" -ForegroundColor Red
        return
    }

    foreach ($group in $groups) {
        $devices = Get-MgGroupMember -GroupId $group.Id -All

        foreach ($device in $devices) {
            $logs = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$($device.DisplayName)'"
            if (!($logs)) {
                Write-Host "Device not found, Check the Device info in Intune"
                logger -type "ERROR" -origin "Get-Intune-Device-Sync-Status.ps1" -message "Device $($device.DisplayName) not found, Check the Device info in Intune......."
                continue
            }

            foreach ($log in $logs) {
                $device_name = $log.deviceName
                $compl_state = $log.complianceState
                $enrolled_date = $log.enrolledDateTime.DateTime
                $last_sync_time = $log.lastSyncDateTime.DateTime
                $Join_type = $log.deviceEnrollmentType
                $azure_ad_reg = $log.azureADRegistered
                $difftime = ([DateTime]$date2 - [DateTime]$last_sync_time).TotalHours

                if ($difftime -le 24) {
                    $status = "IN sync with Intune"
                } else {
                    $status = "NOT in sync with Intune"
                }

                $Hash = [pscustomobject] [ordered] @{
                    'Device Name' = "$device_name"
                    'Last Sync Time' = $last_sync_time
                    'Sync Status' = $status
                    'Enrolled Date' = $enrolled_date
                    'Compliance State' = $compl_state
                    'Join_type' = $Join_type
                    'Azure AD Registered' = $azure_ad_reg
                }
                $deviceHash += $Hash
            }
        }
    }

    $deviceHash | Select-Object "Device Name", "Last Sync Time", "Sync Status", "Enrolled Date", "Compliance State", "Join_type", "Azure AD Registered" | Export-Csv "C:\Temp\device_sync_status_report.csv" -Force -NoTypeInformation
    #logger -type "INFO" -origin "Get-Intune-Device-Sync-Status.ps1" -message "Device Sync status has been written into file ..\utils\device_sync_status_report.csv......."
}

# Define your credentials
$ClientId = ""
$TenantId = ""
$ClientSecret = ""

# Call the function with the provided credentials
Intune-Device-Sync-status -ClientId $ClientId -TenantId $TenantId -ClientSecret $ClientSecret
