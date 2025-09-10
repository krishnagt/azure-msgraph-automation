<#
###############################################################################
# File: Enable-Telemetry-Alerts.ps1
#
# Category: Monitoring / Automation / Windows System Health
#
# Description:
# This PowerShell script creates and schedules a monitoring script 
# (Monitoring.ps1) to continuously track critical system health events 
# on Windows devices. The monitoring script logs events into a local file 
# (C:\Temp\Log\Monitoring.Log), which can be later ingested into Azure 
# Log Analytics or other monitoring tools.
#
# Key Features:
# - Generates Monitoring.ps1 with event collection logic.
# - Tracks system restarts, shutdowns, crashes, and network disconnections.
# - Monitors battery health and power status for tablets/laptops.
# - Logs all captured events with timestamps, system name, and severity.
# - Creates a scheduled task under SYSTEM account to run Monitoring.ps1 
#   every 5 minutes.
# - Ensures idempotency (updates or reuses the scheduled task if it exists).
#
# Date: 14-02-2021
###############################################################################
#>


# Content for the Script getting scheduled in Tablet for Monitoring


$content = @'
<#
 File: Monitoring.PS1
 Description: This Monitors and  generates customs log for Azure Log Analytics
#>
### Global Variable ###
$SiteDetail = "CustomerABC"
$LocalTime = Get-Date -Format "dd/MMM/yyyy:HH:mm:ss zzz"
$OutFile = "C:\Temp\Log\Monitoring.Log"
### End Of Global Variable ###
# Check if Log File exists
If (!(Test-Path $OutFile))
	{
		New-Item $OutFile -Force 
	}
	
# Update Restart event-logs
Function RestartEvent
{
	$StartTime = (Get-Date).AddMinutes(-5)
	$EndTime = Get-Date
	$RestartEvent = (Get-WinEvent -FilterHashtable @{logname = 'System'; id = 1074 ; StartTime=$StartTime; EndTime=$EndTime} -MaxEvents 1 | Where-Object {$_.Message -match "restart"}).Message
	$RestartEvent = ($RestartEvent -split("reason:") | select -First 1) -split("for the following") | select -First 1
	$Restarttime = (Get-WinEvent -FilterHashtable @{logname = 'System'; id = 1074} -MaxEvents 1 | Where-Object {$_.Message -match "restart"}).TimeCreated
	
	If ($RestartEvent)
	{
		Write-Output "$LocalTime $SiteDetail $ENV:COMPUTERNAME Status:Critical Message: System Restarted at $Restarttime $RestartEvent"
	}
}
	
# Update Power Off event-logs
Function PowerOffEvent
{
	$StartTime = (Get-Date).AddMinutes(-5)
	$EndTime = Get-Date
	$PowerOffEvent = (Get-WinEvent -FilterHashtable @{logname = 'System'; id = 1074 ; StartTime=$StartTime; EndTime=$EndTime} -MaxEvents 1 | Where-Object {$_.Message -match "Power Off"}).Message
	$PowerOffEvent = ($PowerOffEvent -split("reason:") | select -First 1) -split("for the following") | select -First 1
	$PowerOfftime = (Get-WinEvent -FilterHashtable @{logname = 'System'; id = 1074} -MaxEvents 1 | Where-Object {$_.Message -match "Power Off"}).TimeCreated
	
	If ($PowerOffEvent)
	{
		Write-Output "$LocalTime $SiteDetail $ENV:COMPUTERNAME Status:Critical Message: System Powered Off at $PowerOfftime $PowerOffEvent"
	}
}
	
# Update System Crash event-logs
Function SystemCrash
{	
	$CrashIDs = "41","1001"
	Foreach ($CrashID in $CrashIDs)
	{
		$StartTime = (Get-Date).AddMinutes(-5)
		$EndTime = Get-Date
		$CrashEvent = (Get-WinEvent -FilterHashtable @{logname = 'System'; id = $CrashID ; StartTime=$StartTime; EndTime=$EndTime} -MaxEvents 1).Message
		$Crashtime = (Get-WinEvent -FilterHashtable @{logname = 'System'; id = $CrashID} -MaxEvents 1).Timecreated 
		
		If ($CrashEvent)
		{
			Write-Output "$LocalTime $SiteDetail $ENV:COMPUTERNAME Status:Critical Message: System Crashed at $Crashtime $CrashEvent"
		}
	}
}
# Network Disconnection event-logs
Function NetworkDisconnection
{	
	$NetworkEventIDs = "27"
	Foreach ($NetworkEventID in $NetworkEventIDs)
	{
		$StartTime = (Get-Date).AddMinutes(-5)
		$EndTime = Get-Date	
		$NetworkEvent = (Get-WinEvent -FilterHashtable @{logname = 'System'; id = $NetworkEventID ; StartTime=$StartTime; EndTime=$EndTime} -MaxEvents 1).Message
		$NetworkEventTime = (Get-WinEvent -FilterHashtable @{logname = 'System'; id = $NetworkEventID} -MaxEvents 1).Timecreated 
		
		If ($NetworkEvent)
		{
			Write-Output "$LocalTime $SiteDetail $ENV:COMPUTERNAME Status:Warning Message: Network Disconnection at $NetworkEventTime "
		}
	}	
}
	
######### Battery Health Check #########
Function BatteryHealth	
{
	$BatteryMinHealth = "99"
	$DesignCapacity = (Get-WmiObject -Class "BatteryStaticData" -Namespace "ROOT\WMI").DesignedCapacity
	$FullChargeCapacity = (Get-WmiObject -Class "BatteryFullChargedCapacity" -Namespace "ROOT\WMI").FullChargedCapacity
	[int]$CurrentHealth = ($FullChargeCapacity/$DesignCapacity) * 100
	if ($CurrentHealth -lt $BatteryMinHealth)
		{
			$BatteryHealthComments = "Battery needs to be replaced"
			Write-Output "$LocalTime $SiteDetail $ENV:COMPUTERNAME Status:Critical Message:$BatteryHealthComments"
		}
	if ($CurrentHealth -ge $BatteryMinHealth)
		{
			$BatteryHealthComments = "Battery is healthy $CurrentHealth"
			#Write-Output "$LocalTime $SiteDetail $ENV:COMPUTERNAME Status:Information	Message:$BatteryHealthComments"
		}
}
# Verify Battery and power Status
Function BatteryPower
{
	
	$BatteryStatus = (Get-CimInstance win32_battery).batterystatus
	
	If($BatteryStatus -eq 2)
	{
		$BatteryPowerComments = "Tablet is connected to Power Adapter"
		#Write-Output "$LocalTime $SiteDetail $ENV:COMPUTERNAME Status:Information Message:$BatteryPowerComments"
	}
	Else
	{	
		$BatteryRemaining = (Get-WmiObject -Class Win32_Battery).EstimatedChargeRemaining 
		$BatteryPowerComments = "Tablet is not Connected to the Power, its running on Battery"
		Write-Output "$LocalTime $SiteDetail $ENV:COMPUTERNAME Status:Warning Message:$BatteryPowerComments, EstimatedChargeRemaining : $BatteryRemaining % " 
	}
}
######### End of Battery Health Check #########
RestartEvent | Out-File -Encoding ASCII -FilePath $OutFile -Append
PowerOffEvent | Out-File -Encoding ASCII -FilePath $OutFile -Append
SystemCrash | Out-File -Encoding ASCII -FilePath $OutFile -Append
NetworkDisconnection | Out-File -Encoding ASCII -FilePath $OutFile -Append
BatteryHealth | Out-File -Encoding ASCII -FilePath $OutFile -Append
BatteryPower | Out-File -Encoding ASCII -FilePath $OutFile -Append
'@



function Enable-Telemetry-Alerts()
{

# Generate the script in local Machine

	$LogDir = "C:\Temp\Log"
	
	If (!(Test-Path $LogDir))
	{
		New-Item -ItemType Directory -Path $LogDir -Force
	}
	
	Out-File -FilePath "C:\Temp\Log\Monitoring.PS1" -Encoding unicode -Force -InputObject $content -Confirm:$false
	
 
# Scheduling the Task in the Tablet 

	Write-Host -ForegroundColor Yellow "********** Creating the task to Monitor the Tablet.....Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") **********"
 
	$ScheduledTaskArguments = '-ExecutionPolicy Bypass -windowstyle Hidden -File "C:\Temp\Log\Monitoring.PS1"'
	$TaskName = "Monitoring Script"
	$TaskPath = "\Azure\"
	$TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
	
# Validate if Task Exists
	if (($TaskExists)-and (Get-ScheduledTask -TaskName $TaskName).Actions[0].Arguments -eq $ScheduledTaskArguments) 
	{
		Write-Host -ForegroundColor Yellow "Task already exists, no update needed."
        Write-ProgressHelper -status 'Telemetry alert script already existed..' -Message ' ' -percent 50
		logger $rocc_hostname Success "Telemetry alert script already existed.." Enable-Telemetry-Alerts.ps1
        Start-Sleep -Seconds 1
        successcount 
	}
	elseif ($TaskExists) 
	{
        $TaskExists.Actions[0].Arguments = $ScheduledTaskArguments
        $TaskExists | Set-ScheduledTask
        Write-Host -ForegroundColor Green "Task has been successfully updated."
        Write-ProgressHelper -status 'Telemetry alert script has been created..' -Message ' ' -percent 50
		logger $rocc_hostname Success "Telemetry alert script has been created.." Enable-Telemetry-Alerts.ps1
        Start-Sleep -Seconds 1
        Check-completionStatus -statuscount 10
	}
	else 
	{
		$StartDateTime = (get-date).AddMinutes(5).ToString("HH:mm")
		$ScheduledTaskAction = New-ScheduledTaskAction -Execute "$($PSHOME)\powershell.exe" -Argument $ScheduledTaskArguments
		$ScheduledTaskTrigger1 = New-ScheduledTaskTrigger -Once -At $StartDateTime -RepetitionInterval (New-TimeSpan -Minutes 5) 

		$ScheduledTaskTriggers = @(
			$ScheduledTaskTrigger1)
    
		$ScheduledTaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Days 999)
		$ScheduledTaskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
		$ScheduledTask = New-ScheduledTask -Action $ScheduledTaskAction -Settings $ScheduledTaskSettings -Trigger $ScheduledTaskTriggers -Principal $ScheduledTaskPrincipal
		Register-ScheduledTask -InputObject $ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
		Start-ScheduledTask $TaskName -TaskPath $TaskPath
		logger $rocc_hostname Success "Task has been successfully created to Monitor the Tablet critical events" Enable-Telemetry-Alerts.ps1
	}
 
	Write-Host -ForegroundColor Green "********** Task has been successfully created to Monitor the Tablet critical events..... Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") **********"
}
