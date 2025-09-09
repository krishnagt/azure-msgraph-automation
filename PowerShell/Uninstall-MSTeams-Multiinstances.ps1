
<#
###############################################################################
# 
# Author: GTKrishna
# File: Uninstall-MicrosoftTeams.ps1
#
# Description:
# This script automates the complete removal of Microsoft Teams from a Windows 
# machine. It performs the following steps:
#
# 1. Detects and uninstalls the "Teams Machine-Wide Installer" if present 
#    (via Win32_Product).
# 2. Detects and uninstalls the standalone "Microsoft Teams" application 
#    from the system registry.
# 3. Invokes the Teams updater (Update.exe) with uninstall arguments to 
#    silently remove the Teams app for the current user.
# 4. Cleans up residual files and directories from the local AppData folder.
#
# The script ensures both the machine-wide installer and per-user Teams 
# instances are removed, leaving no leftover Teams directories.
#
# Date: 15-10-2024
###############################################################################
#>

# Define the product name of Teams Machine-Wide Installer
$teamsInstallerProductName = "Teams Machine-Wide Installer"

# Get the installed programs using WMI
$installedPrograms = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%$teamsInstallerProductName%'"

# Check if Teams Machine-Wide Installer is installed
if ($installedPrograms) {
    # Uninstall Teams Machine-Wide Installer
    foreach ($program in $installedPrograms) {
        Write-Host "Uninstalling $($program.Name)..."
        $uninstallResult = $program.Uninstall()

        # Check the uninstall result
        if ($uninstallResult.ReturnValue -eq 0) {
            Write-Host "Uninstall successful."
        } else {
            Write-Host "Uninstall failed. Return Code: $($uninstallResult.ReturnValue)"
        }
    }
} else {
    Write-Host "Teams Machine-Wide Installer is not installed."
}


# Define the registry path for Microsoft Teams
$teamsRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"

# Get the list of subkeys (installed programs) under the Teams registry path
$teamsRegistryKeys = Get-Item -LiteralPath $teamsRegistryPath | Get-ItemProperty | Where-Object { $_.DisplayName -eq "Microsoft Teams" }

# Check if Microsoft Teams is installed
if ($teamsRegistryKeys) {
    # Uninstall Microsoft Teams
    foreach ($key in $teamsRegistryKeys) {
        $uninstallString = $key.UninstallString
        Write-Host "Uninstalling Microsoft Teams..."
        Start-Process $uninstallString -Wait
        Write-Host "Uninstall successful."
    }
} else {
    Write-Host "Microsoft Teams is not installed."
}

#################################

function Uninstall-MSTeams()
{
    $TeamsPath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams')
    $TeamsUpdateExePath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams', 'Update.exe')
    try
    {
        Write-ProgressHelper -status ' ' -Message 'Starting MSTeams Uninstallation....'
        if (Test-Path -Path $TeamsUpdateExePath) 
        {
            Write-Host -ForegroundColor Green "Uninstalling MSTeams............. "
            # Uninstall app
            $proc = Start-Process -FilePath $TeamsUpdateExePath -ArgumentList "-uninstall -s" -PassThru
            $proc.WaitForExit()
            Write-ProgressHelper -status 'Uninstallation of MSTeams Success!' -Message ' ' -percent 30
            #logger $devicename Success "Uninstallation of MSTeams Success! " Uninstall.ps1
            Start-Sleep -Seconds 1
            
        }
        else 
        {
            Write-ProgressHelper -status 'Could not find MSTeams!' -Message ' ' -percent 30
            Start-Sleep -Seconds 1
            #logger $devicename Fail "Could not find MSTeams!Failed! " Uninstall.ps1
        }
        if (Test-Path -Path $TeamsPath) 
        {
            Write-Host "Deleting Teams directory"
            Remove-Item -Path $TeamsPath -Recurse            
        }
    }
    catch
    {
        Write-Error -ErrorRecord $_
        #logger $devicename Fail "Could not find MSTeams!Failed! " Uninstall.ps1
    }
}
