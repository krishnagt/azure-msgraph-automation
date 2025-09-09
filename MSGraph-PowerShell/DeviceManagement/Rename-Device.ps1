<#
###############################################################################
# 
# Author: GTKrishna
# File: Rename-IntuneManagedDevice.ps1
#
# Description:
# This script connects to Microsoft Intune via the Microsoft Graph API and 
# performs a remote action to rename a Windows device managed in Intune.
#
# Key steps:
# 1. Installs and imports the Microsoft.Graph.Intune PowerShell module (if missing).
# 2. Authenticates to Microsoft Graph using Connect-MSGraph.
# 3. Defines the request URL for Intune managed device actions.
# 4. Prepares a JSON payload to set the device name for a specific managed device.
# 5. Sends the request to Microsoft Graph with Invoke-MSGraphRequest.
# 6. Handles errors gracefully if the rename action fails.
#
# Notes:
# - Device ID must be obtained from Intune and included in the JSON payload.
# - Supports dynamic naming using %RAND% placeholder for random digits.
# - Requires appropriate Intune admin/Graph API permissions.
#
# Date: 15-10-2024
###############################################################################
#>




#Install PowerShell SDK for Microsoft Intune Graph API
If ((Get-Module Microsoft.Graph.Intune) -eq $null) {
    Install-Module -Name Microsoft.Graph.Intune
}

#Connect to Microsoft Graph
$ConnectGraph = Connect-MSGraph

#Set the request URL
$URL = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/executeAction"

#Set the JSON payload
$JSONPayload = @"
{
	action: "setDeviceName",
	actionName: "setDeviceName",
	deviceIds: ["d8cd02c1-9443-4ad0-8681-937c2e6d7607"],
	deviceName: "CLDCLN%RAND:2%",
	platform: "windows",
	realAction: "setDeviceName",
	restartNow: false
}
"@

#Invoke the Microsoft Graph request
Try {        
    Invoke-MSGraphRequest -HttpMethod POST -Url $URL -Content $JSONPayload -Verbose -ErrorAction Stop
}
Catch {
    Write-Output "Failed to rename the Windows devices"
}
