#GTKrishna
#This PowerShell function initiates a remote restart for devices managed in Microsoft Intune.

#It accepts a target Azure AD group name as input.

#Retrieves all devices that are members of the specified group.

#For each device, it triggers an Intune-managed device reboot action.

#Logs the restart activity for auditing/troubleshooting purposes.

#This script is useful for administrators who need to remotely reboot one or more devices directly from Intune without logging into the Intune Portal.
#


<# This function initiates 'Restart'from Intune Portal for particular Device #>

Function Intune-Single-Reboot()
{
  param (
        [Parameter(Mandatory = $True,Position = 1)]
        [string]$GroupName
        )

$group=Get-AzureADGroup -Filter "DisplayName eq '$GroupName'"
$device=Get-AzureADGroupMember -ObjectId $group.ObjectId
    foreach ($i in $device.DisplayName)
    {
      Get-IntuneManagedDevice -Filter "contains(deviceName,'$i')" | Invoke-IntuneManagedDeviceRebootNow
      logger -type "Info" -origin "Intune-Single-Reboot.ps1" -message "Restart has been initiated for Device $i ......."

    }
}

Intune-Single-Reboot
