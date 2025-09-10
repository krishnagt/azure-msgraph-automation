<#
###############################################################################
# Author: GTKrishna
# File: Invoke-Device-Delete-AD-Action.ps1
#
# Description:
# This PowerShell function connects to Azure Active Directory and deletes 
# one or more device records based on a search string (e.g., computer name).  
# It queries Azure AD for matching devices and removes them using the 
# Remove-AzureADDevice cmdlet.
#
# Key functions:
# - Searches for device objects in Azure AD using Get-AzureADDevice.
# - Iterates through all matching devices and deletes them.
# - Provides console output for success, failure, or "not found" scenarios.
# - Implements basic error handling with try/catch.
#
# Example:
# Invoke-Device-Delete-AD-Action -ComputerName "TestDevice01"
# (Deletes the specified Azure AD device record if found.)
#
# Notes:
# - Requires AzureAD PowerShell module.
# - Ensure sufficient permissions to delete device objects in Azure AD.
# - Recommended for cleanup of stale or decommissioned devices.
#
# Date: 15-10-2024
###############################################################################
#>



<#
.SYNOPSIS
This function is used to set a generic intune resources from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and sets a generic Intune Resource
.EXAMPLE
Invoke-DeviceAction -DeviceID $DeviceID -remoteLock
Resets a managed device passcode
.NOTES
NAME: Invoke-DeviceAction
#>

Function Invoke-Device-Delete-AD-Action() {

 Try
    {
        Write-host "Retrieving " –NoNewline
        Write-host "Azure AD " –ForegroundColor Yellow –NoNewline
        Write-host "device record/s…" –NoNewline 
        [array]$AzureADDevices = Get-AzureADDevice –SearchString $ComputerName –All:$true –ErrorAction Stop
        If ($AzureADDevices.Count -ge 1)
        {
            Write-Host "Success" –ForegroundColor Green
            Foreach ($AzureADDevice in $AzureADDevices)
            {
                Write-host "   Deleting DisplayName: $($AzureADDevice.DisplayName)  |  ObjectId: $($AzureADDevice.ObjectId)  |  DeviceId: $($AzureADDevice.DeviceId) …" –NoNewline
                Remove-AzureADDevice –ObjectId $AzureADDevice.ObjectId –ErrorAction Stop
                Write-host "Success" –ForegroundColor Green
            }      
        }
        Else
        {
            Write-host "Not found!" –ForegroundColor Red
        }
    }
    Catch
    {
        Write-host "Error!" –ForegroundColor Red
        $_
    }
}

Invoke-Device-Delete-AD-Action
