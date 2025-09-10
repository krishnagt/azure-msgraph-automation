<#
###############################################################################
# Author: GTKrishna
# File: Disable-Teams-Autorun.ps1
#
# Description:
# This PowerShell script disables Microsoft Teams from automatically launching 
# at user login. It removes the Teams autorun registry entry and updates the 
# Teams configuration file (desktop-config.json) to ensure "openAtLogin" is set 
# to false.
#
# Key functions:
# - Checks and removes Teams autorun entry from registry (HKCU Run key).
# - Reads Teams configuration file (desktop-config.json).
# - Updates "openAtLogin" setting to false, or creates it if missing.
# - Writes updated configuration back to disk.
# - Validates if Teams is installed by checking Update.exe path before execution.
#
# Notes:
# - Intended for environments where Teams auto-start is not desired.
# - Requires user context execution since it modifies HKCU and AppData.
# - Safe to run multiple times (idempotent).
#
# Date: 15-10-2024
###############################################################################
#>

Function Disable-Teams-Autorun()
{
# If Teams autorun entry exists, remove it
$TeamsAutoRun = (Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -ea SilentlyContinue)."com.squirrel.Teams.Teams"
if ($TeamsAutoRun)
{
    Remove-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "com.squirrel.Teams.Teams"
}

# Teams Config Data
$TeamsConfig = "$env:APPDATA\Microsoft\Teams\desktop-config.json"
$global:TeamsConfigData = Get-Content $TeamsConfig -Raw -ea SilentlyContinue | ConvertFrom-Json

# If Teams already doesn't have the autostart config, exit
If ($TeamsConfigData)
{
    If ($TeamsConfigData.appPreferenceSettings.openAtLogin -eq $false)
    {
        # It's already configured to not startup
        exit
    }
    else
    {
        # If Teams hasn't run, then it's not going to have the openAtLogin:true value
        # Otherwise, replace openAtLogin:true with openAtLogin:false
        If ($TeamsConfigData.appPreferenceSettings.openAtLogin -eq $true)
        {
            $TeamsConfigData.appPreferenceSettings.openAtLogin = $false
        }
        else
        # If Teams has been intalled but hasn't been run yet, it won't have an autorun setting
        {
            $Values = ($TeamsConfigData.appPreferenceSettings | GM -MemberType NoteProperty).Name
            If ($Values -match "openAtLogin")
            {
                $TeamsConfigData.appPreferenceSettings.openAtLogin = $false
            }
            else
            {
                $TeamsConfigData.appPreferenceSettings | Add-Member -Name "openAtLogin" -Value $false -MemberType NoteProperty
            }
        }
        # Save
        $TeamsConfigData | ConvertTo-Json -Depth 100 | Out-File -Encoding UTF8 -FilePath $TeamsConfig -Force
    }
 }
}


#Disable Teams Autorun if it is already installed 
    $installpath = "$($env:LOCALAPPDATA)\Microsoft\Teams"
    if (Test-Path "$($installpath)\Update.exe") 
    {
        Disable-Teams-Autorun  
    }
