<#
 File: System.PS1
 Description: This script fetches and validates System related pre-requsites parameters
 Date: 13/19/2021
#>

# Baseline Parameters for System

	If ($Environment -eq "System")
	{
		$RAMBaseline = [int]"8"
		$DiskFreeSpaceBaseline = [int]"100"
	}

Function Get-DiskSize {
	$Disks = @()
	$DiskObjects = Get-WmiObject -namespace "root/cimv2" -query "SELECT Name, Capacity, FreeSpace FROM Win32_Volume"
	$DiskObjects | % {
	$Disk = New-Object PSObject -Property @{
	Name           = $_.Name
	FreeSpace      = [math]::Round($_.FreeSpace / 1073741824)
	}
	$Disks += $Disk
	}
	Write-Output $Disks | Sort-Object Name
}

# System Base information
	
	#Write-Verbose "Fetching the Base System Configuration..." -Verbose
	$Hostname = $env:COMPUTERNAME
	$SystemHash = @()
	$hash = New-Object PSObject -property @{Parameters="System hostname";Value="$Hostname";Status="Pass";Comments=""}
	$SystemHash += $hash
	
	$TabletManufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
	$hash = New-Object PSObject -property @{Parameters="Manufacturer";Value="$TabletManufacturer";Status="Pass";Comments=""}
	$SystemHash += $hash
	
	$TabletModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
	$hash = New-Object PSObject -property @{Parameters="Model";Value="$TabletModel";Status="Pass";Comments=""}
	$SystemHash += $hash
	

	$TabletSerialNumber = (Get-WmiObject win32_bios).SerialNumber
	$hash = New-Object PSObject -property @{Parameters="System Serial Number";Value="$TabletSerialNumber";Status="Pass";Comments=""}
	$SystemHash += $hash
	
	# System Base OS Check
	#Write-Verbose "Fetching the Base System Operating System Details..." -Verbose
	$TabletOS = (Get-WmiObject -class Win32_OperatingSystem).Caption
	$TabletOSName =(Get-WmiObject -Class win32_operatingsystem).Version
	$TabletOSNum = [int]($SystemOSName |%{$_.Split('.')[0];})
	
	If ($SystemOSNum -eq 10)
	{
		$SystemOSstatus = "Pass"
	}
	Else
	{
		$SystemOSstatus = "Fail"
		$SystemOSComments = "System is running not running on Windows 10" 
	}
	
	$hash = New-Object PSObject -property @{Parameters="OS Name";Value="$TabletOS";Status="$TabletOSstatus";Comments="$TabletOSComments"}
	$SystemHash += $hash
	
# System OS Build Pre Check
	
	#Write-Verbose "Fetching the System OS Build..." -Verbose	
	$TabletOSbuild = [int]((Get-WmiObject -Class win32_operatingsystem).BuildNumber)
	
	If($TabletOSbuild -ge 19043)
	{
	   $OSBuildstatus = "Pass"
	}
	Else 
	{
	   $OSBuildstatus = "Fail"
	   $OSBuildstatusComments = "OS Build is older than 19043"
	}
	$hash = New-Object PSObject -property @{Parameters="OS Build";Value="$TabletOSbuild";Status="$OSBuildstatus";Comments="$OSBuildstatusComments"}
	$SystemHash += $hash
	
# System OS Version Pre Check
	
	#Write-Verbose "Fetching the System OS Version..." -Verbose	
	
	IF ($TabletOSbuild -eq 19043)
	{
		$TabletOSVersion = "21H1"
	}
	ElseIF ($TabletOSbuild -eq 19042)
	{
		$TabletOSVersion = "20H2"
	}
	ElseIF ($TabletOSbuild -eq 19041)
	{
		$TabletOSVersion = "2004"
	}
	ElseIF ($TabletOSbuild -eq 18363)
	{
		$TabletOSVersion = "1909"
	}
	Else
	{
		$TabletOSVersion
	}
	
	If($TabletOSbuild -ge 19043)
	{
	   $TabletOSVersionStatus = "Pass"
	}
	Else
	{
	   $TabletOSVersionStatus = "Fail"
	   $TabletOSVersionStatusComments = "System running on older than 21H1 version"
	}
	$hash = New-Object PSObject -property @{Parameters="OS Version";Value="$TabletOSVersion";Status="$TabletOSVersionStatus";Comments="$TabletOSVersionStatusComments"}
	$SystemHash += $hash
	


# System RAM Pre Check

	$Memory = 0
	$Mems = (((Get-WmiObject win32_physicalmemory).Capacity)) 
	
	ForEach ($Mem in $Mems)
	{
		$Memory = $Memory + $Mem
	}
	$RAM = ((($Memory/1024)/1023)/1024)
	$RAMinGB = [int]$RAM

	If($RAMinGB -ge $RAMBaseline)
	{
		$RAMStatus = "Pass"
	}
	Else
	{
		$RAMStatus = "Fail"
		$RAMStatusComments = "Available RAM is only $RAMinGB GB. Required is $RAMBaseline GB"
	}
	$hash = New-Object PSObject -property @{Parameters="RAM Size";Value="$RAMinGB GB";Status="$RAMStatus";Comments="$RAMStatusComments"}
	$SystemHash += $hash	

# System Disk Space Pre Check

	$DiskFreeSpaceinGB = (Get-DiskSize | ? {$_.Name -eq 'c:\'}).freespace
	
	If($DiskFreeSpaceinGB -ge $DiskFreeSpaceBaseline)
	{
		$DiskStatus = "Pass"
	}
	Else
	{
		$DiskStatusComments = "Only $DiskFreeSpaceinGB GB Free Space left. Required is $DiskFreeSpaceBaseline GB"
		$DiskStatus = "Fail"
	}
	$hash = New-Object PSObject -property @{Parameters="Disk Free Space";Value="$DiskFreeSpaceinGB GB";Status="$DiskStatus";Comments="$DiskStatusComments"}
	$SystemHash += $hash

# System Processor Pre Check
	
	$Processor = (Get-CimInstance -Class CIM_Processor -ErrorAction Stop).Name
	
	If($Processor -like '*i3*')
	{
		$ProcessorStatus = "Pass"
	}
	ElseIf ($Processor -like '*i5*')
	{
		$ProcessorStatus = "Pass"
	} 
	ElseIf ($Processor -like '*i7*')
	{
		$ProcessorStatus = "Pass"
	}
	ElseIf ($Processor -like '*Xeon*')
	{
		$ProcessorStatus = "Pass"
	} 
	Else 
	{
		$ProcessorStatus = "Fail"
		$ProcessorStatusComments = "Processor is niether Intel i3/i5/i7/Xeon Series"
	}
	$hash = New-Object PSObject -property @{Parameters="CPU Model";Value="$Processor";Status="$ProcessorStatus";Comments="$ProcessorStatusComments"}
	$SystemHash += $hash
	
	
# Time Drift and NTP Check
	#Write-Verbose "Verifying the Time Drift..." -Verbose	
	$TabletTimeZoneLocation = (Get-TimeZone).DisplayName
	$TabletTimeZone = (Get-TimeZone).StandardName

	$TimeDriftinRaw = w32tm /stripchart /computer:time.windows.com /samples:1 /dataonly | select -last 1
	$TimeDrifterror = $TimeDriftinRaw | where {$_ -match "error"}
	$TimeDriftMinus = $TimeDriftinRaw | where {$_ -match "\-"}
	If ($TimeDrifterror)
	{
		$TimeDriftStatus = "Fail"
		$TimeDriftStatusComments = "NTP Server not reachable"
	}
	ElseIf ($TimeDriftMinus) 
	{
		$TimeDriftinSec = (($TimeDriftinRaw.split(",")[1]).split(".")[0])
		$TimeDriftDec = -$TimeDriftinSec/60
		$TimeDrift = [int]$TimeDriftDec
		
		If ($TimeDrift -le 5)
		{	
			$TimeDriftStatus = "Pass"
			$TabletDriftValue = "No Time Drift observed"
		}
		Else
		{
			$TimeDriftStatus = "Fail"
			$TimeDriftStatusComments = "Time Drift is $TimeDrift Minutes, and Fix it manually"
		}
		
	}
	Else
	{
		$TimeDriftinSec = (($TimeDriftinRaw.split(",")[1]).split(".")[0])
		$TimeDriftDec = $TimeDriftinSec/60
		$TimeDrift = [int]$TimeDriftDec
		
		If ($TimeDrift -le 5)
		{	
			$TimeDriftStatus = "Pass"
			$TabletDriftValue = "No Time Drift observed"
		}
		Else
		{
			$TimeDriftStatus = "Fail"
			$TimeDriftStatusComments = "Time Drift is $TimeDrift Minutes, and Fix it manually"
		}
	}
	
	$hash = New-Object PSObject -property @{Parameters="Time Zone Location";Value="$TabletTimeZoneLocation";Status="$TimeDriftStatus";Comments="$TimeDriftStatusComments"}
	$SystemHash += $hash
	
	$hash = New-Object PSObject -property @{Parameters="Time Drift";Value="$TabletDriftValue";Status="$TimeDriftStatus";Comments="$TimeDriftStatusComments"}
	$SystemHash += $hash


# Verify Battery and power Status

	If ($Environment -eq "System")
	{
	
		#Write-Verbose "Verifying the Battery Status..." -Verbose
		$OutBatteryPath = "$RootDir\battery_report.html"
		
		#Check to see if the local cache directory is present
		If ((Test-Path -Path $OutBatteryPath) -eq $false)
		{
			#Create the file to store Intune policies 
			New-Item -ItemType File $OutBatteryPath -Force -Confirm:$False
		}
		else
		{
			Clear-Content -Path $OutBatteryPath
		}

		powercfg /batteryreport /output $OutBatteryPath
		$BatteryStatus = (Get-CimInstance win32_battery).batterystatus
		$est_charge_remaining=(Get-WmiObject win32_battery).estimatedChargeRemaining
		$est_run_time=(Get-WmiObject win32_battery).EstimatedRunTime
		#$design_voltg=(Get-WmiObject win32_battery).DesignVoltage
		#$full_charge_capacity = (Get-WmiObject win32_battery).FullChargeCapacity 
		#$no_of_batt_available=(Get-WmiObject win32_battery).Availability 
		$Bat_name=(Get-WmiObject win32_battery).Name
		$hours=(new-timespan -minutes $est_run_time).Hours		
		If($BatteryStatus -eq 2)
		{
			$Battery = "Pass"
			$BatteryStatus = "Battery is connected to Power Adaptor"
			$hash = New-Object PSObject -property @{Parameters="Battery Status";Value="$BatteryStatus";Status="$Battery";Comments="$BatteryComments"}
			$SystemHash += $hash

		}
		Else
		{
			$Battery = "Fail"
			$BatteryComments = "System is not Connected to the Power, its running on Battery ($Bat_name),Estimated Charge Remaining $est_charge_remaining%,Estimated run time $est_run_time Mins($hours Hours), Find complete Battery report here $OutBatteryPath "
			$hash = New-Object PSObject -property @{Parameters="Battery Status";Value="$BatteryStatus";Status="$Battery";Comments="$BatteryComments"}
			$SystemHash += $hash
		}
		
	}
write-host -ForegroundColor Green "System Validation has been Completed"
#### End of System Verification ####
