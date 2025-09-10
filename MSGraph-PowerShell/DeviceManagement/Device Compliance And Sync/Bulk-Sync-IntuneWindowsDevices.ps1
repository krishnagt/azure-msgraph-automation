<#
###############################################################################
# Author: GTKrishna
# File: Bulk-Sync-IntuneWindowsDevices.ps1
#
# Description:
# This PowerShell script connects to Microsoft Graph API using client 
# credentials and identifies Azure AD groups that follow the naming pattern 
# "*-W10". It retrieves all Windows devices linked to members of these groups, 
# filters for compliant devices, and prepares them for remote sync operations.
#
# Key functions:
# - Installs/imports Microsoft.Graph PowerShell module if missing.
# - Authenticates to Microsoft Graph using ClientId, TenantId, and ClientSecret.
# - Finds Azure AD groups ending with "-W10".
# - Collects all group members and their managed devices.
# - Filters devices running Windows with a "compliant" compliance state.
# - Outputs device counts and prepares them for Sync requests.
#
# Notes:
# - Requires Microsoft Graph API application with appropriate Intune permissions.
# - Scopes used: DeviceManagementManagedDevices.PrivilegedOperations.All,
#                DeviceManagementManagedDevices.ReadWrite.All,
#                DeviceManagementManagedDevices.Read.All
# - The actual sync action (Sync-MgDeviceManagementManagedDevice) is commented out 
#   but can be enabled as needed.
#
# Date: 15-10-2024
###############################################################################
#>




# Connect to Microsoft Graph with the required scopes
#Connect-MgGraph -scope DeviceManagementManagedDevices.PrivilegedOperations.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementManagedDevices.Read.All

# Check if the Microsoft Graph PowerShell module is installed, if not, install it
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}

# Import the Microsoft Graph module
Import-Module Microsoft.Graph

# Define the credentials
$ClientId = "your-client-id"
$TenantId = "your-tenant-id"
$ClientSecret = "your-client-secret"

# Connect to Microsoft Graph with the required scopes using the provided credentials
$secureClientSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$credentials = New-Object -TypeName Microsoft.Graph.Auth.ClientCredentialProvider -ArgumentList $ClientId, $secureClientSecret, $TenantId
Connect-MgGraph -ClientCredential $credentials -Scopes "DeviceManagementManagedDevices.PrivilegedOperations.All", "DeviceManagementManagedDevices.ReadWrite.All", "DeviceManagementManagedDevices.Read.All"


# Get all groups
$allGroups = Get-MgGroup -All

# Filter groups that end with '-W10'
$groups = $allGroups | Where-Object { $_.DisplayName -match 'Devices-W10' }

if ($groups.Count -eq 0) {
    Write-Host "No groups found ending with '-W10'" -ForegroundColor Red
    exit
}

# Get members from all W10 groups
$groupMembers = @()
foreach ($group in $groups) {
    $members = Get-MgGroupMember -GroupId $group.Id -All
    $groupMembers += $members
}

write-host " No of devices/users found in W10 groups $($groupMembers.Count)"

# Get device details for each user
$Windowsdevices = @()
foreach ($member in $groupMembers) {
    $userDevices = Get-MgDeviceManagementManagedDevice -Filter "userPrincipalName eq '$($member.UserPrincipalName)'"
}
    foreach ($device in $userDevices) {
        if ($device.OperatingSystem -eq "Windows" -and $device.ComplianceState -eq "compliant") {
            $Windowsdevices += $device
        }
    }

Write-Host " No of devices which are associated to User $($userDevices.Count)"
Write-Host " No.of Windows Devices which are Complient $($Windowsdevices.Count) devices"

$currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Foreach ($device in $Windowsdevices) {
    Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $device.id
    Write-Host "$currentTime - Sending device sync request to" $device.DeviceName -ForegroundColor Yellow
}

