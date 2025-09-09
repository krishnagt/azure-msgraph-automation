<#
###############################################################################
# 
# Author: GTKrishna
# File: Wait-For-Internet.ps1
#
# Description:
# This PowerShell script waits for an active internet connection before allowing
# further execution. It continuously checks the system’s network adapters and
# connection profiles until internet connectivity is detected or a timeout is reached. 
# Logs the status and time taken into a log file for auditing or troubleshooting.
#
# Key Functions:
# - Sets execution policy to Bypass for script execution.
# - Validates network adapter configuration to check for default gateways.
# - Uses Get-NetConnectionProfile to verify IPv4 internet connectivity.
# - Implements a timeout (default 5 minutes) to avoid infinite waiting.
# - Logs progress and final status into C:\Temp\Log\logstest.txt.
#
# Use Case:
# Ideal for scripts that depend on internet availability (e.g., cloud operations,
# updates, or deployments) to ensure connectivity before proceeding.
#
# Category:
# PowerShell → Networking → Connectivity Checks
#
# Date: 15-10-2024
###############################################################################
#>


Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
 $TempDir="C:\Temp\Log"
 start-sleep -seconds 5
 $x = gwmi -class Win32_NetworkAdapterConfiguration | where { $_.DefaultIPGateway -ne $null }
# If there is (at least) one available, exit the loop.
  if ( ($x | measure).count -gt 0 ) 
  {
    $timeoutInSeconds = 300  # Set the timeout duration in seconds (e.g., 5 minutes)
    $startTime = Get-Date
   $AllNetConnectionProfiles = Get-NetConnectionProfile | Where-Object {$_.IPv4Connectivity -eq 'Internet'}
      while ((Get-Date) -lt ($startTime).AddSeconds($timeoutInSeconds) -and -not (($AllNetConnectionProfiles | measure).count -gt 0)) {
     Start-Sleep -Seconds 10
     Add-Content C:\Temp\Log\logstest.txt "Waiting for Internet......"

     }

   if ( ($AllNetConnectionProfiles | measure).count -gt 0 )
    {
    Add-Content C:\Temp\Log\logstest.txt "Internet is now connected. Time taken: $($elapsedTime.TotalSeconds) seconds. Continue with the script."	  
    }
else{
     Add-Content C:\Temp\Log\logstest.txt "Internet is not connected. Time taken: $($elapsedTime.TotalSeconds) seconds. Continue with the script."				   
    } 
  }
  else {
     Add-Content C:\Temp\Log\logstest.txt "Internet is not connected. Time taken: $($elapsedTime.TotalSeconds) seconds. Continue with the script."
     }  
